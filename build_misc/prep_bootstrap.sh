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
    while [ -z "$PASSWORD1" ] || [ ! "$PASSWORD1" = "$PASSWORD2" ]; do
            PASSWORDS="$(@MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/uialert -b "In order to use command line tools like \"sudo\" after jailbreaking, you will need to set a terminal passcode. (This cannot be empty)" --secure "Password" --secure "Repeat Password" -p "Set" "Set Password" | @MEMO_PREFIX@@MEMO_SUB_PREFIX@/bin/head -n 1)"
            PASSWORD1="$(printf "%s\n" "$PASSWORDS" | /var/jb/usr/bin/sed -n '1 p')"
            PASSWORD2="$(printf "%s\n" "$PASSWORDS" | /var/jb/usr/bin/sed -n '2 p')"
    done
    printf "%s\n" "$PASSWORD1" | @MEMO_PREFIX@@MEMO_SUB_PREFIX@/sbin/pw usermod 501 -h 0
fi

rm -f @MEMO_PREFIX@/prep_bootstrap.sh
