# Alpine + wire-desktop-bin
  * This is not a sandbox
  * Container user will be set to Xorg user's uid:gid, this makes the rw ~/Downloads/ folder possible
  * Changing .Xauthority auth family to FamilyWild on .Xauthority does not seem to work anymore. This is why Docker mimics hostname
  * Some musl-libc packages would not play with glibc. Pre-compiled packages from Arch are used instead

