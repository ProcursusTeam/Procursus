#!/bin/sh -e

for rc in @MEMO_PREFIX@/etc/Muttrc.d/*.rc; do
    test -r "$rc" && echo "source \"$rc\""
done

# vi: ft=sh
