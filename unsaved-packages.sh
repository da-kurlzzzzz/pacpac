#!/bin/bash

# script to get packages, which are not in my great package list (packages.yml)
# if you run this - feed the file to the script:
# ./unsaved-packages.sh packages.yml

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
grep -v $(printf -- '-e ^%s$ ' $PKGLIST) <<< $ALL && echo ":unsaved" || true
grep -v $(printf -- '-e ^%s$ ' $ALL) <<< $PKGLIST && echo ":uninstalled" || true
