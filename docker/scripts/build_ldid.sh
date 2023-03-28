#!/bin/bash
set -e

# ldid
git clone https://github.com/ProcursusTeam/ldid.git /tmp/ldid
pushd /tmp/ldid
make
mv -f ./ldid /usr/local/bin/ldid
chmod +x /usr/local/bin/ldid
popd

rm -rf /tmp/ldid
