#!/usr/bin/env bash
# Bootstrap a checkra1n device immediately after first boot.
startiproxy() {
    echo "Starting iproxy."
    command iproxy 37512 44 > /dev/null 2>&1 &
}

stopiproxy() {
    pkill -f "iproxy"
}

scpfile() {
    /usr/bin/env expect <(cat << EOF
spawn scp -P ${PORT} $1 root@${IP}:/var/root
expect {
    "The authenticity of host" {
        send "yes\r"
        exp_continue
    } assword: {
        send "${PASSWORD}\r"
        exp_continue
    } incorrect {
        send_user "invalid password or account\n"
        exit
    } timeout {
        send_user "connection to ${IP} timed out\n"
        exit
    } refused {
        send_user "connection to host failed"
        exit
    }
}
EOF
)
}

sshcommand() {
    /usr/bin/env expect <(cat << EOF
spawn ssh -t root@${IP} -p ${PORT} $1
expect {
    "The authenticity of host" {
        send "yes\r"
        exp_continue
    } assword: {
        send "${PASSWORD}\r"
        exp_continue
    } incorrect {
        send_user "invalid password or account\n"
        exit
    } timeout {
        send_user "connection to ${IP} timed out\n"
        exit
    } refused {
        send_user "connection to host failed"
        exit
    }
}
EOF
)
}

IP="localhost"
TMP=$(mktemp -d)
PASSWORD="alpine"

cd $(dirname "$0")
if [[ "${IP}" == "localhost" ]]; then
    PORT=37512
    startiproxy
else
    PORT=22
fi
echo "Download Zebra."
ZEBRADEB=xyz.willy.zebra_1.1_iphoneos-arm.deb
wget -q -nc -P ${TMP} https://getzbra.com/repo/pkgfiles/${ZEBRADEB}
echo "Bootstrapping..."
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "[${IP}]:${PORT}"
scpfile '${BUILD_STRAP}/bootstrap.tar.zst'
scpfile ''${TMP}'/'${ZEBRADEB}''
scpfile ''${BUILD_STAGE}'/zstd/usr/bin/zstd' # Insert an actually signed zstd bin here later. This is just a placeholder.
sshcommand 'mount -o rw,union,update /'
sshcommand 'mv zstd /usr/bin'
sshcommand '/usr/bin/zstd -d bootstrap.tar.zst > bootstrap.tar'
sshcommand 'tar --preserve-permissions -xf bootstrap.tar -C /'
sshcommand '/usr/libexec/firmware'
sshcommand 'PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games\" dpkg -i '${ZEBRADEB}''
sshcommand '/usr/bin/snaputil -n \$(/usr/bin/snaputil -l /) orig-fs /'
sshcommand 'touch /.bootstrapped && touch /.mount_rw'
sshcommand '/Library/dpkg/info/profile.d.postinst'
sshcommand '/Library/dpkg/info/openssh.postinst'
echo "Cleanup."
rm -rf ${TMP}
if [[ "${IP}" == "localhost" ]]; then
    stopiproxy
fi
echo "Done."
