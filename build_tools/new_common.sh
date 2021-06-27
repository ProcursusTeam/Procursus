#!/usr/bin/env bash

ask() {
	[ -z "${1+x}" ] && exit 1
	if [ -z "${2+x}" ]; then
		read -p "${1}: " rc
	else
		rc="$2"
	fi
	echo "$rc"
}

checkpkg() {
	if [ -f $1.mk ]; then
		>&2 echo "$1.mk already exists."
		exit 1
	elif grep -R "^$pkg:" *.mk &> /dev/null; then
		>&2 echo "$1 already exists."
		exit 1
	fi
}

downloadlink() {
	if [ "$(${SED} 's|^.*://||' <<< "${1}" | cut -d'/' -f1)" = "github.com" ]; then
		echo -e "\t$\(call GITHUB_ARCHIVE,$(${SED} 's|^.*://||' <<< "${1}" | cut -d'/' -f2),$(${SED} 's|^.*://||' <<< "${1}" | cut -d'/' -f3),$\(${4}_VERSION\),$(echo "${1}" | rev | cut -d'/' -f1 | rev | ${SED} 's/\.tar.*//g' | ${SED} "s/${2}//g")$\(${4}_VERSION\)\)"
	else
		if echo "${1}" | rev | cut -d'/' -f1 | rev | ${SED} 's/\.tar.*//g' | ${SED} "s/${2}//g" | grep "${3}" &>/dev/null; then
			echo -e "\twget -q -nc -P\$(BUILD_SOURCE) $(${SED} "s/${2}/\$(${4}_VERSION)/g" <<< "$1")"
		else
			echo -e "\t-[ ! -f "$\(BUILD_SOURCE\)/${3}-$\(${4}_VERSION\).tar.$(rev <<< "$download" | cut -d'.' -f1 | rev)" ] \&\& \\
\t	\twget -q -nc -O\$(BUILD_SOURCE)/${3}-\$(${4}_VERSION).tar.$(rev <<< "$download" | cut -d'.' -f1 | rev) \\
\t	\t\t$(${SED} "s/${2}/\$(${4}_VERSION)/g" <<< "$1")"
		fi
	fi
}

ask_extended_description() {
if [ -z "$1" ]; then
	ESCAPED_DESCRIPTION=""
	>&2 echo "Extended Description (press ENTER then Ctrl+D when done):"
	while read line
        	do ESCAPED_DESCRIPTION="$ESCAPED_DESCRIPTION"" $line\n"
	done
else
	ESCAPED_DESCRIPTION="$(echo "$1" | ${SED} '$!s/$/\\n/' | tr -d '\n' | ${SED} 's|^| |g')"
	fi
	echo "$ESCAPED_DESCRIPTION"
}

createfromtemplate() {
	${SED} $SED_OPTIONS -e "s/@pkg@/${pkg}/g" \
		-e "s/@PKG@/${formatpkg}/g" \
		-e "s/@PKG_VERSION@/${ver}/g" \
		-e "s/@SOVER@/${sover}/g" \
		-e "s/@Section@/${Section}/g" \
		-e "s|@DEB_DESCRIPTION@|${description}|g" \
		-e "s|@DEB_EXTENDED_DESCRIPTION@|${extended_description}|g" \
		-e "s|@download@|$(downloadlink "$download" "$ver" "$pkg" "$formatpkg")|g" \
		-e "s|@compression@|$(rev <<< "$download" | cut -d'.' -f1 | rev)|g" \
		"$1" > "$2" || /dev/null
}

if command -v gsed &>/dev/null; then
	SED=gsed
else
	SED=sed
fi
