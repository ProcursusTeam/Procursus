#!/usr/bin/env bash
# This script is simply to check if anything's been linked to libintl without my knowledge.
if [[ "$(uname -s)" == "Darwin" ]]; then
    OTOOL='otool -L'
    AWK='gawk'
elif [[ "$(uname -s)" == "Linux" ]]; then
    OTOOL='aarch64-apple-darwin-otool -L'
    AWK='awk'
else
    echo "Use a good OS please."
fi
cd $(dirname "$0")
for bin in $(find ../build_stage/*{/usr,}/{s,}bin ../build_stage/*/usr/lib -type f); do
    if [[ -f ${bin} ]] && [[ ! -h ${bin} ]]; then
        if [[ $(${OTOOL} ${bin} | grep intl) ]]; then
            if [[ ! $(grep gettext ../$(echo "${bin}" | cut -d'/' -f3).mk) ]]; then
                output="$(echo "${bin}" | cut -d'/' -f3) ${output}"
            fi
        fi
    fi
done
if [[ -n "${output}" ]]; then
    echo "***** The following link libintl without you knowing! *****"
    echo "${output}" | ${AWK} -v RS="[ \n]+" '!n[$0]++'
else
    echo "***** No programs link libintl without you knowing *****"
fi