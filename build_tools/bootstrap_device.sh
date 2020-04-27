#!/usr/bin/env bash
# Bootstrap a checkra1n device immediately after first boot.
startiproxy() {
    echo "Starting iproxy."
    command iproxy 2222 44 > /dev/null 2>&1 &
}

stopiproxy() {
    pkill -f "iproxy"
}

scpfile() {
    /usr/bin/expect <(cat << EOF
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
    /usr/bin/expect <(cat << EOF
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
    PORT=2222
    startiproxy
else
    PORT=22
fi
echo "Download Zebra."
wget -q -nc -P ${TMP} https://github.com/wstyres/Zebra/raw/gh-pages/beta/pkgfiles/xyz.willy.zebra_1.1%7Ebeta7_iphoneos-arm.deb
echo "Bootstrapping..."
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "[localhost]:2222"
scpfile '../build_strap/'${PLATFORM}'/bootstrap.tar.gz'
scpfile ''${TMP}'/xyz.willy.zebra_1.1~beta6_iphoneos-arm.deb'
sshcommand 'mount -o rw,union,update /'
sshcommand 'tar --preserve-permissions -xzf bootstrap.tar.gz -C /'
sshcommand '/usr/libexec/firmware'
sshcommand 'PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games\" dpkg -i xyz.willy.zebra_1.1~beta6_iphoneos-arm.deb'
sshcommand '/binpack/etc/ssl/bin/snappy -f / -r \$(/binpack/etc/ssl/bin/snappy -f / -l | sed -n 2p) -t orig-fs'
sshcommand 'touch /.bootstrapped && touch /.mount_rw'
sshcommand '/Library/dpkg/info/profile.d.postinst'
echo "Cleanup."
rm -rf ${TMP}
if [[ "${IP}" == "localhost" ]]; then
    stopiproxy
fi
echo "Done."