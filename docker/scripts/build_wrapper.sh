#!/bin/bash
set -e

TRIPLES=(
  "armv7-apple-darwin"
  "armv7k-apple-darwin"
  "aarch64-apple-darwin"
  "x86_64-apple-darwin"
)

wget -P /tmp https://raw.githubusercontent.com/ProcursusTeam/Procursus/main/build_tools/wrapper.c

mkdir -p /usr/local/bin

cc -O2 -Wall -Wextra -Wno-address -Wno-incompatible-pointer-types -pedantic \
  /tmp/wrapper.c \
  -o /usr/local/bin/clang-wrap

for TRIPLE in "${TRIPLES[@]}"; do
  ln -f /usr/local/bin/clang-wrap /usr/local/bin/${TRIPLE}-clang
  ln -f /usr/local/bin/clang-wrap /usr/local/bin/${TRIPLE}-clang++
done
