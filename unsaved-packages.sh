#!/bin/bash

# Enhanced script to manage installed packages and compare them with a YAML package list
# Usage: ./unsaved-packages.sh [-i | -r | -a | -I] [-f human|minimal|yaml] [package_list_file]

# Configuration
PACMAN="yay"  # Package manager to use
PKGFILE_DEFAULT="$(dirname "$(realpath "$0")")/packages.yml"  # Default YAML file
AUTO_COMMENT="added automatically"  # Comment for auto-added packages
HOSTNAME=$(hostname)  # Current machine's hostname

# Colors for human-readable output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"  # No Color

# Functions for better modularity
print_usage() {
    echo "Usage: $0 [-i | -r | -a | -I] [-f human|minimal|yaml] [package_list_file]"
    echo "  -i: Print only packages you might want to install"
    echo "  -r: Print only packages you might want to remove"
    echo "  -a: Add missing packages to the YAML file"
    echo "  -I: Interactive mode (prompt for actions)"
    echo "  -f: Output format (human, minimal, yaml)"
    echo "  -h: Show this help message"
}

get_package_list() {
    local pkgfile="$1"
    # Extract package names, filtering by hostname if machines field exists
    yq -r ".packages[] | select(.machines == null or (.[\"machines\"] | index(\"$HOSTNAME\"))) | .name" "$pkgfile"
}

get_group_list() {
    local pkgfile="$1"
    yq -r '.packages[] | select(has("group")).name' "$pkgfile"
}

get_installed_packages() {
    local grouped_packages="$1"
    if [ -z "$grouped_packages" ]; then
        $PACMAN -Qqe
    else
        $PACMAN -Qqe | grep -v $(printf -- '-e ^%s$ ' $grouped_packages)
    fi
}

compare_packages() {
    local installed="$1"
    local saved="$2"
    local print_unsaved="$3"
    local print_uninstalled="$4"

    if $print_unsaved; then
        grep -v $(printf -- '-e ^%s$ ' $saved) <<< "$installed"
    fi

    if $print_uninstalled; then
        grep -v $(printf -- '-e ^%s$ ' $installed) <<< "$saved"
    fi
}

add_packages_to_yml() {
    local pkgfile="$1"
    local packages_to_add="$2"
    local tmp_pkgfile="$pkgfile.tmp"
    cp "$pkgfile" "$tmp_pkgfile"
    local yq_command=".packages += ["
    for pkg in $packages_to_add; do
        yq_command="$yq_command{\"name\": \"$pkg\", \"comment\": \"$AUTO_COMMENT\"},"
    done
    yq_command="${yq_command%,}]"
    yq -i -Y "$yq_command" "$tmp_pkgfile"
    local stripped="$pkgfile.str"
    yq -Y . "$pkgfile" > "$stripped"
    local output="$pkgfile.out"
    diff "$stripped" "$tmp_pkgfile" | patch -o "$output" "$pkgfile"
    rm "$tmp_pkgfile" "$stripped"
    echo -e "${GREEN}Added packages to $output. Please review manually.${NC}"
}

interactive_mode() {
    local pkgfile="$1"
    local unsaved_packages="$2"
    local uninstalled_packages="$3"

    if [ -n "$unsaved_packages" ]; then
        echo -e "${YELLOW}The following packages are installed but not in $pkgfile:${NC}"
        echo -e "$unsaved_packages" | column -x
        read -p "Do you want to add them to $pkgfile? [y/N] " yn
        case $yn in
            [Yy]*) add_packages_to_yml "$pkgfile" "$unsaved_packages";;
        esac
    fi

    if [ -n "$uninstalled_packages" ]; then
        echo -e "${YELLOW}The following packages are in $pkgfile but not installed:${NC}"
        echo -e "$uninstalled_packages" | column -x
        read -p "Do you want to install them? [y/N] " yn
        case $yn in
            [Yy]*) $PACMAN -S $uninstalled_packages;;
        esac
    fi
}

# Main script logic
main() {
    local print_unsaved=false
    local print_uninstalled=false
    local add_packages=false
    local interactive=false
    local output_format="human"

    # Parse command-line options
    while getopts ":irf:aIHh" opt; do
        case $opt in
            i) print_uninstalled=true;;
            r) print_unsaved=true;;
            f) output_format="$OPTARG";;
            a) add_packages=true;;
            I) interactive=true;;
            h) print_usage; exit;;
            *) echo "Invalid option: -$OPTARG" >&2; print_usage; exit 1;;
        esac
    done

    shift $((OPTIND-1))

    # Get the package list file (either from argument or default)
    local pkgfile="${1:-$PKGFILE_DEFAULT}"

    # Extract package and group lists from the YAML file
    local saved_packages=$(get_package_list "$pkgfile")
    local groups=$(get_group_list "$pkgfile")

    # Get installed packages (excluding grouped packages if any)
    local grouped_packages=""
    if [ -n "$groups" ]; then
        grouped_packages=$($PACMAN -Qqg $groups)
    fi
    local installed_packages=$(get_installed_packages "$grouped_packages")

    # Compare packages
    local unsaved_packages=$(compare_packages "$installed_packages" "$saved_packages" true false)
    local uninstalled_packages=$(compare_packages "$installed_packages" "$saved_packages" false true)

    # Handle interactive mode
    if $interactive; then
        interactive_mode "$pkgfile" "$unsaved_packages" "$uninstalled_packages"
        exit
    fi

    # Handle adding packages
    if $add_packages; then
        add_packages_to_yml "$pkgfile" "$unsaved_packages"
        exit
    fi

    # Output results based on the selected format
    case "$output_format" in
        human)
            if $print_unsaved && [ -n "$unsaved_packages" ]; then
                echo -e "${YELLOW}Packages installed but not in $pkgfile:${NC}"
                echo -e "$unsaved_packages" | column -x
            fi
            if $print_uninstalled && [ -n "$uninstalled_packages" ]; then
                echo -e "${YELLOW}Packages in $pkgfile but not installed:${NC}"
                echo -e "$uninstalled_packages" | column -x
            fi
            ;;
        minimal)
            if $print_unsaved; then
                echo "$unsaved_packages"
            fi
            if $print_uninstalled; then
                echo "$uninstalled_packages"
            fi
            ;;
        yaml)
            echo "unsaved_packages:"
            echo "$unsaved_packages" | sed 's/^/  - /'
            echo "uninstalled_packages:"
            echo "$uninstalled_packages" | sed 's/^/  - /'
            ;;
        *)
            echo "Invalid output format: $output_format" >&2
            exit 1
            ;;
    esac
}

# Run the script
main "$@"
