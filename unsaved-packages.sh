#!/bin/bash

# script to get packages, which are not in my great package list (packages.yml)
# if you run this - feed the file to the script:
# ./unsaved-packages.sh packages.yml

print_unsaved=false
print_uninstalled=false
print_notes=true

# -i - print only packages you might want to install
# -r - print only packages you might want to remove

while getopts ":irh" opt
do
    case $opt in
        i) print_notes=false; print_uninstalled=true;;
        r) print_notes=false; print_unsaved=true;;
        h) echo "usage: $0 [-i | -r | -h] [package_list_file]"; exit;;
    esac
done

shift $((OPTIND-1))

if $print_notes
then
    print_uninstalled=true
    print_unsaved=true
fi

# here it comes

# choose your warrior
PACMAN=yay

# get file either from $1 or from default location
PKGFILE=${1:-"$(dirname $(realpath $0))/packages.yml"}

# get just package names
PKGLIST=$(yq -r '.packages[].name' ${PKGFILE})

# there is no way to list installed groups so just get group names from file
GROUPLIST=$(yq -r '.packages[] | select(has("group")).name' ${PKGFILE})

# get packages from groups
[ -z $GROUPLIST ] || GROUPED=$($PACMAN -Qqg $GROUPLIST)

# get all others
UNGROUPED=$($PACMAN -Qqe | grep -v $(printf -- '-e ^%s$ ' $GROUPED))

# merge them
ALL="$UNGROUPED"

[ -z $GROUPLIST ] || ALL+="
$GROUPLIST"

# and compare
if $print_unsaved
then
    grep -v $(printf -- '-e ^%s$ ' $PKGLIST) <<< $ALL
    $print_notes && echo ":unsaved"
fi

if $print_uninstalled
then
    grep -v $(printf -- '-e ^%s$ ' $ALL) <<< $PKGLIST
    $print_notes && echo ":uninstalled"
fi
