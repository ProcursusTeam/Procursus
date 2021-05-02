#!/usr/bin/env bash
for makefile in *.mk; do
	if ! grep -q 'MEMO_PREFIX' $makefile; then
		if grep -q 'usr' $makefile; then
			print="$makefile "
			if grep -q 'etc' $makefile; then
				print+='etc '
			fi
			if grep -q 'var' $makefile; then
				print+='var'
			fi
			echo -e "$print"
		fi
	fi
done
