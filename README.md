# Package list
The idea is simple - store list of installed packages in a format, which would
be both human-readable and suitable for use in a script.  So now if I ever
need a fresh Arch Linux installation I can just do

    unsaved-packages.sh | cut -sf2 | yay -S -

And everything will be installed

Important: file format was changed from plain text to yaml and most remarks
are useless now. I will update README soon

# Basic syntax
The syntax in comments is as of now just meant for stuff like `grep` but maybe
I'll extend the scripts's capabilities

* `aur` means what it says - the package is from AUR
* `systemctl {word}` means that there is a service which should be started
* `^` means that a package is either an optional dependency or just helps a
  package above it
* `config [manual]` means that default behaviour of a program isn't what I
  want and there is probably a config file somewhere, but maybe it's just
  easier to open a program and change settings

<!-- vim:set tw=78: -->
