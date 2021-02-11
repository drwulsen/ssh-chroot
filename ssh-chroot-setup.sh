#!/bin/bash
## Script to auto-populate a chroot folder for SSH users with programs of choice
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit 1
fi

chrootdir=""
if [ -z "$1" ]; then
	echo "No chroot path given, exiting for your own safety"
	exit 1
else
	chrootdir="$( readlink -f ${1} )"
fi

### START OF USER EDITABLE VARIABLES ###

## Binaries to copy into the chroot, auto-copying required libraries as well.
programs=(
	"/bin/bash"
	"/bin/ls"
	"/bin/mkdir"
	"/usr/bin/git"
	"/usr/bin/git-receive-pack"
	"/usr/bin/git-upload-pack"
	"/usr/bin/git-upload-archive"
)

## List of directories to create in any case
static_dirs=(
	"/dev"
)

## Files to copy in any case
static_files=(
	"/etc/passwd"
	"/etc/group"
)

## Device nodes to create, actually parameters for mknod.
## Sample syntax to create null as character device with major 1 and minor 3: "null,c 1 3"
devnodes=(
	"null,c 1 3"
	"tty,c 5 0"
	"zero,c 1 5"
	"random,c 1 8"
)
### END OF USER EDITABLE VARIABLES ###

#write a message, ${!1} allows us to pass variable names
#for example, "e_arg_1" will print the value of variable "e_arg_1"
message() {
	echo -e "${!1} ${2} ${3}"
}

#throw an error message and exit
error() {
	echo -ne "\nERROR: "
	message "$1" "$2"
	exit 1
}

#check for and in case of errors, exit
#"$1" is the return code handed over from the caller, "$2" an additional message to print.
checkfail() {
	if [[ "$1" -ne 0 ]]; then
		error "e_sub_1" "$2"
	fi
}

## Concatenate directories into one array, do the same for files.
## This will come in handy if more user input arrays are defined.
dirlist=(
	"${static_dirs[@]}"
)

## Generate binaries dependencies and folder structure list
	filelist+=$(ldd ${programs[*]} | grep -o -e '\/.* ' | sed -e 's/\ //g' | sort | uniq )
	filelist+=(
	"${programs[@]}"
	"${static_files[@]}"
)

## Create directory structure and copy all that was requested.
mkdir --parents --verbose "$chrootdir"
for i in "${dirlist[@]}"; do
	mkdir --parents --verbose "${chrootdir}${i}"
	checkfail "$?" "mkdir --parents --verbose ${chrootdir}${i}"
done

for i in ${filelist[@]}; do
	cp --parents "$i" "$chrootdir"
	checkfail "$?" "cp --parents $i $chrootdir"
done

for i in "${devnodes[@]}"; do
	device="$(echo "$i" | cut -d ',' -f 1)"
	mode="$(echo "$i" | cut -d ',' -f 2)"
	rm --force "${chrootdir}/dev/${device}"
	checkfail "$?" "rm --force ${chrootdir}/dev/${device}"
	mknod --mode 666 "${chrootdir}/dev/${device}" ${mode}
	checkfail "$?" "mknod --mode 666 ${chrootdir}/dev/${device} ${mode}"
done
