#!/bin/sh

@MEMO_PREFIX@/Library/dpkg/info/darwintools.postinst
@MEMO_PREFIX@/Library/dpkg/info/system-cmds.postinst
@MEMO_PREFIX@/Library/dpkg/info/debianutils.postinst configure 99999
@MEMO_PREFIX@/Library/dpkg/info/apt.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/zsh.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/bash.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/vi.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/openssh-server.extrainst_ install @SSH_STRAP@

chsh -s @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/zsh mobile
chsh -s @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/zsh root

rm -f @MEMO_PREFIX@/prep_bootstrap.sh
