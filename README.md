# Package list
The idea is simple - store list of installed packages in a format, which would
be both human-readable and suitable for use in a script.  So now if I ever
need a fresh Arch Linux installation I can just do

    pacpac

And after interactive setup everything will be installed

# Basic syntax
* `machines` and `exclude-machines` are for choosing whether this particular
  hostname should have this package
* `aur` means what it says - the package is from AUR
* `systemctl {word}` means that there is a service which should be started
* `needs-manual-config` means that default behaviour of a program isn't what I
  want and there is probably a config file somewhere, but maybe it's just
  easier to open a program and change settings

<!-- vim:set tw=78: -->
