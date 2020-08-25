#!/usr/bin/env bash
cd "$(dirname $0)"
mkdir -p ./"${1}"_"${2}"_"${3}"/DEBIAN
touch ./"${1}"_"${2}"_"${3}"/DEBIAN/control
echo -e "Package: ${1}\nMaintainer: Hayden Seay\nVersion:${2}\nArchitecture:${3}\nSection: Dummy_Packages\nDescription: Dummy package to help migration from other bootstraps. Safe to remove.\n" > ./"${1}"_"${2}"_"${3}"/DEBIAN/control
dpkg-deb -b ./"${1}"_"${2}"_"${3}"
rm -rf ./"${1}"_"${2}"_"${3}"
