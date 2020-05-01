#!/usr/bin/env bash
# This script is simply to check if anything's been linked to libintl without my knowledge.
for bin in $(find ${BUILD_STAGE}/*{/usr,}/{s,}bin ${BUILD_STAGE}/*/usr/lib -type f); do
    if [[ -f ${bin} ]] && [[ ! -h ${bin} ]]; then
        if [[ $(${OTOOL} -L ${bin} | grep intl) ]]; then
            if [[ ! $(grep gettext ${BUILD_ROOT}/$(echo "${bin}" | ${SED} 's/.*'${MEMO_TARGET}'\/\(.*\)\/usr.*/\1/').mk) ]]; then
                output="$(echo "${bin}" | cut -d'/' -f3) ${output}"
            fi
        fi
    fi
done
if [[ -n "${output}" ]]; then
    echo "********** The following link libintl without you knowing! **********"
    echo "${output}" | awk -v RS="[ \n]+" '!n[$0]++'
else
    echo "********** No programs link libintl without you knowing **********"
fi
