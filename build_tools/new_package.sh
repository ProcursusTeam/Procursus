#!/usr/bin/env bash

ask() {
	[ -z ${1+x} ] && exit 1
	if [ -z ${2+x} ]; then
		read -p "${1}: " rc
	else
		rc=$2
	fi
	echo "$rc"
}

dialog_inputbox() {
	dialog \
		--colors --no-cancel --title "$1" \
		--inputbox "$2" ${3:-15} ${4:-40} 3>&1 1>&2 2>&3 3>&-
}

checkpkg() {
	if [ -f makefiles/$1.mk ]; then
		echo "$1.mk already exists."
		return 1
	elif grep -R "^$pkg:" makefiles/*.mk &>/dev/null; then
		echo "$1 already exists."
		return 1
	fi
}

checkbuild() {
	if [ ! -f build_misc/templates/$1.mk ]; then
		echo "$1 is not a valid buildsystem"
		return 1
	fi
}

downloadlink() {
	if [ "$(${SED} 's|^.*://||' <<<"${1}" | cut -d'/' -f1)" = "github.com" ]; then
		echo -e "\t$\(call GITHUB_ARCHIVE,$(${SED} 's|^.*://||' <<<"${1}" | cut -d'/' -f2),$(${SED} 's|^.*://||' <<<"${1}" | cut -d'/' -f3),$\(${4}_VERSION\),$\(${4}_VERSION\)\)"
	else
		if echo "${1##*/}" | ${SED} 's/-//g' | ${SED} 's/\.tar.*//g' | ${SED} "s/${2}//g" | grep "${3}" &>/dev/null; then
			echo -e "\twget2 -q -nc -P\$(BUILD_SOURCE) $(${SED} "s/${2}/\$(${4}_VERSION)/g" <<<"$1")"
		else
			echo -e "\t-[ ! -f "$\(BUILD_SOURCE\)/${3}-$\(${4}_VERSION\).tar.${download##*.}" ] \&\& \\
\t	\twget2 -q -nc -O\$(BUILD_SOURCE)/${3}-\$(${4}_VERSION).tar.${download##*.}) \\
\t	\t\t$(${SED} "s/${2}/\$(${4}_VERSION)/g" <<<"$1")"
		fi
	fi
}

main() {
	pkg="$(ask "Package Name" $1)"
	checkpkg "$pkg" || exit 1
	formatpkg="$(${SED} -e 's|-|_|g' -e "s|\(.\)|\u\1|g" <<<"${pkg}")"

	while true; do
		build="$(ask "Build System (type ? to list all build systems)" $2)"
		if [ "$build" = "?" ]; then
			echo "Available build systems:"
			find build_misc/templates -name '*.mk' -not -name 'keyring.mk' -exec basename '{}' .mk \; | $SED 's/^/- /g'
		else
			if checkbuild "$build"; then
				break
			elif ! [ -z "$2" ]; then
				exit 1
			fi
		fi
	done

	ver="$(ask "Package Version" $3)"
	download="$(ask "Tarball Download Link" $4)"
	${SED} -e "s/@pkg@/${pkg}/g" \
		-e "s/@PKG@/${formatpkg}/g" \
		-e "s/@PKG_VERSION@/${ver}/g" \
		-e "s|@download@|$(downloadlink "$download" "$ver" "$pkg" "$formatpkg")|g" \
		-e "s|@compression@|${download##*.}|g" \
		"build_misc/templates/${build}.mk" > "makefiles/${pkg}.mk"
	${SED} -e "s/@pkg@/${pkg}/g" \
		-e "s/@PKG@/${formatpkg}/g" \
		"build_misc/templates/package.control" > "build_info/${pkg}.control"
}

main_dialog() {
	pkg=$(dialog_inputbox "New package" "Package name")
	if ! checkpkg "$pkg"; then
		dialog --msgbox "$pkg already exists" 15 40
		clear
		exit 1
	fi
	formatpkg="$(${SED} -e 's|-|_|g' -e "s|\(.\)|\u\1|g" <<<"${pkg}")"

	buildsystems=()
	count=1
	for i in ./build_misc/templates/*.mk; do
		if ! [ "$(basename $i .mk)" = "keyring" ]; then
			buildsystems+=($count $(basename $i .mk))
			count=$((count + 1))
		fi
	done
	build=$(dialog \
		--colors --no-cancel --title 'New package' \
		--menu 'Build System' 15 40 $count "${buildsystems[@]}" 3>&1 1>&2 2>&3 3>&-)
	build=${buildsystems[(( build*2-1 ))]}

	ver=$(dialog_inputbox "New package" "Package version")
	download=$(dialog_inputbox "New package" "Tarball download link")
	${SED} -e "s/@pkg@/${pkg}/g" \
		-e "s/@PKG@/${formatpkg}/g" \
		-e "s/@PKG_VERSION@/${ver}/g" \
		-e "s|@download@|$(downloadlink "$download" "$ver" "$pkg" "$formatpkg")|g" \
		-e "s|@compression@|${download##*.}|g" \
		"build_misc/templates/${build}.mk" > "makefiles/${pkg}.mk"
	${SED} -e "s/@pkg@/${pkg}/g" \
		-e "s/@PKG@/${formatpkg}/g" \
		"build_misc/templates/package.control" > "build_info/${pkg}.control"
	clear
}

if command -v gsed &>/dev/null; then
	SED=gsed
else
	# shellcheck disable=SC2209
	SED=sed
fi

if command -v dialog &>/dev/null && [ -z "$1" ]; then
	main_dialog
else
	main $@
fi
