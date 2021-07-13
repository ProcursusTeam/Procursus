#!/bin/sh

if [ "$1" = "-h" ]; then
	echo './build_tools/new_keyring.sh [firstlast|screenname] [email or KEYID]'
	exit 1
fi

ask() {
	[ -z ${1+x} ] && exit 1
	if [ -z ${2+x} ]; then
		read -p "${1}: " rc
	else
		rc=$2
	fi
	echo "$rc"
}

main() {
	name="$(ask "Name [Ex: Cameron Katri]" $1)"
	pkg="$(ask "Package name [Ex: cameronkatri]" $1)"
	keyid="$(ask "KEYID (or email)" $2)"
	mkdir -p build_misc/keyrings/$pkg/
	gpg --output build_misc/keyrings/$pkg/$pkg.gpg --export $keyid
	sed -e "s|@pkg@|${pkg}|g" \
		-e "s|@PKG@|$(echo ${pkg} | tr a-z A-Z)|g" \
		-e "s|@date@|$(date +%Y.%m.%d)|g" \
		build_misc/templates/keyring.mk > makefiles/${pkg}-keyring.mk
	sed -e "s|@pkg@|${pkg}|g" \
		-e "s|@PKG@|$(echo ${pkg} | tr a-z A-Z)|g" \
		-e "s|@NAME@|${name}|g" \
		build_misc/templates/keyring.control > build_info/${pkg}-keyring.control
}

main $@
