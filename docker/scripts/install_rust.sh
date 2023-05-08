#!/bin/bash
set -e

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly --no-modify-path -y

RUST_TARGETS=(
  "aarch64-apple-darwin"
  "aarch64-apple-ios"
  "aarch64-apple-tvos"
  "x86_64-apple-darwin"
)

for TARGET in "${RUST_TARGETS[@]}"; do
  rustup target add ${TARGET}
done