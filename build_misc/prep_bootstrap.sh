#!@MEMO_PREFIX@/bin/sh

@MEMO_PREFIX@@MEMO_SUB_PREFIX@/libexec/firmware
@MEMO_PREFIX@@MEMO_SUB_PREFIX@/sbin/pwd_mkdb -p @MEMO_PREFIX@/etc/master.passwd >/dev/null 2>&1
@MEMO_PREFIX@/Library/dpkg/info/debianutils.postinst configure 99999
@MEMO_PREFIX@/Library/dpkg/info/apt.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/dash.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/zsh.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/bash.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/vi.postinst configure 999999
@MEMO_PREFIX@/Library/dpkg/info/openssh-server.extrainst_ install @SSH_STRAP@

@MEMO_PREFIX@@MEMO_SUB_PREFIX@/sbin/pwd_mkdb -p @MEMO_PREFIX@/etc/master.passwd

@MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/chsh -s @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/zsh mobile
@MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/chsh -s @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/zsh root

if [ -z "$NO_PASSWORD_PROMPT" ]; then
    PASSWORD=""
    while [ -z "$PASSWORD" ]; do
            PASSWORD=$(/var/jb/usr/bin/uialert -b "In order to use command line tools like \"sudo\" after jailbreaking, you will need to set a terminal passcode. (This cannot be empty)" --secure "Password" -p "Set" "Set Password" | /var/jb/usr/bin/head -n 1)
    done
    echo "$PASSWORD" | /var/jb/usr/sbin/pw usermod 501 -h 0
fi

rm -f @MEMO_PREFIX@/prep_bootstrap.sh
