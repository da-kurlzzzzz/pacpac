#!/bin/bash

# script to get packages, which are not in my great package list (packages.yml)
# if you run this - feed the file to the script:
# ./unsaved_packages.sh packages.yml

# here it comes

# choose your warrior
PACMAN=yay

# get file either from $1 or from default location
PKGFILE=${1:-"$(dirname $(realpath $0))/packages.yml"}

# get just package names
PKGLIST=$(yq -r '.packages[].name' ${PKGFILE} | sort)

# there is no way to list installed groups so just get group names from file
GROUPLIST=$(yq -r '.packages[] | select(has("group")).name' ${PKGFILE} | sort)

# get packages from groups
GROUPED=$($PACMAN -Qg $GROUPLIST | cut -d' ' -f2)

# get all others
UNGROUPED=$(printf -- '-e "^%s$" ' $GROUPED | xargs grep -v <($PACMAN -Qqe))

# merge them
ALL="$UNGROUPED
$GROUPLIST"

# and compare
comm -3 <(sort <<< $ALL) - <<< $PKGLIST
