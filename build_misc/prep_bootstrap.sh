#!@MEMO_PREFIX@/bin/sh

@MEMO_PREFIX@/Library/dpkg/info/darwintools.postinst
@MEMO_PREFIX@/Library/dpkg/info/system-cmds.postinst
@MEMO_PREFIX@/Library/dpkg/info/debianutils.postinst configure 99999
@MEMO_PREFIX@/Library/dpkg/info/apt.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/zsh.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/bash.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/openssh-server.extrainst_ install @SSH_STRAP@

@MEMO_PREFIX@@MEMO_SUB_PREFIX@/sbin/pwd_mkdb -p @MEMO_PREFIX@/etc/master.passwd

@MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/chsh -s @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/zsh mobile
@MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/chsh -s @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/zsh root

rm -f @MEMO_PREFIX@/prep_bootstrap.sh
