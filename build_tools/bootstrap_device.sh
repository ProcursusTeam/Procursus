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
expect "root@${IP}'s password:"
send "${PASSWORD}\r"
interact
EOF
)
}

sshcommand() {
    /usr/bin/expect <(cat << EOF
spawn ssh -t root@${IP} -p ${PORT} $1
expect "root@${IP}'s password:"
send "${PASSWORD}\r"
interact
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
wget -q -nc -P ${TMP} https://github.com/wstyres/Zebra/raw/gh-pages/beta/pkgfiles/xyz.willy.zebra_1.1%7Ebeta5-2_iphoneos-arm.deb
echo "Bootstrapping..."
scpfile '../build_strap/bootstrap.tar.gz'
scpfile ''${TMP}'/xyz.willy.zebra_1.1~beta5-2_iphoneos-arm.deb'
sshcommand 'mount -o rw,union,update /'
sshcommand 'tar --preserve-permissions -xvzf bootstrap.tar.gz -C /'
sshcommand '/usr/libexec/firmware'
sshcommand 'PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games\" /bin/bash -c \"dpkg -i xyz.willy.zebra_1.1~beta5-2_iphoneos-arm.deb\"'
sshcommand '/binpack/etc/ssl/bin/snappy -f / -r \$(/binpack/etc/ssl/bin/snappy -f / -l | sed -n 2p) -t orig-fs'
sshcommand 'touch /.bootstrapped && touch /.mount_rw'
sshcommand '/Library/dpkg/info/profile.d.postinst'
echo "Cleanup."
rm -rf ${TMP}
if [[ "${IP}" == "localhost" ]]; then
    stopiproxy
fi
echo "Done."