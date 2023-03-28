#!/bin/bash
set -e

# Procursus Debian dependency installer

PACKAGES=(
  "build-essential"
  "clang"
  "llvm"
  "make"
  "coreutils"
  "findutils"
  "sed"
  "tar"
  "patch"
  "bash"
  "openssl"
  "gnupg"
  "libtool"
  "automake"
  "bison"
  "flex"
  "groff"
  "pseudo"
  "dpkg"
  "zstd"
  "libncurses6"
  "wget"
  "cmake"
  "docbook-xsl"
  "python3"
  "git"
  "pkg-config"
  "autopoint"
  "po4a"
  "unzip"
  "triehash"
  "meson"
  "ninja-build"
  "curl"
  "xsltproc"
)

apt-get update
apt-get install -y ${PACKAGES[@]}
