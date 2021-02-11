# ssh-chroot
Create a chroot folder for SSH connections

This script can be edited to include binaries of your liking.
It will then copy the binaries and their corresponding dependencies to your chosen chroot path (only argument read by this script)
Further, it will create device nodes as desired in your target chroot path.
At last, it copies the /etc/passwd and /etc/group file there.

The point of it is to easily set up a chroot directory for ssh connections, also it can be hooked to your package manager of choice to update the chroot after system updates.
