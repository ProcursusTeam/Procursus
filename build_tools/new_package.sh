#!/usr/bin/env bash

source ./build_tools/new_common.sh

checkbuild() {
	if [ ! -f build_misc/templates/$1-lib.mk ]; then
		>&2 echo "$1 is not a valid buildsystem"
		exit 1
	fi
}

main() {
	pkg="$(ask "Package Name" $1)"
	checkpkg "$pkg"
	formatpkg="$(${SED} -e 's|-|_|g' -e "s|\(.\)|\u\1|g" <<< "${pkg}")"
	build="$(ask "Build System" $2)"
	checkbuild "$build"
	ver="$(ask "Package Version" $3)"
	download="$(ask "Download Link" $4)"
	Section="$(ask "Section" $5)"
	description="$(ask "Description" $6)"
	extended_description="$(ask_extended_description "$7")"
	echo "Writing out control and makefile"
	createfromtemplate build_misc/templates/${build}.mk ${pkg}.mk
	createfromtemplate build_misc/templates/${build}-pkg.control build_info/${pkg}.control
}

main $@
