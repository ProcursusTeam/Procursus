#!/bin/sh

/Library/dpkg/info/darwintools.postinst
/Library/dpkg/info/system-cmds.postinst
/Library/dpkg/info/debianutils.postinst configure 99999
/Library/dpkg/info/apt.postinst configure 999999
/Library/dpkg/info/zsh.postinst configure 999999
/Library/dpkg/info/bash.postinst configure 999999

chsh -s /bin/zsh mobile
chsh -s /bin/zsh root

rm -f /prep_bootstrap.sh