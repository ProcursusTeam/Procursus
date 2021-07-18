#!/bin/sh

if ! command -v jq >/dev/null; then
    echo 'Please install "jq" to use this script.' >&2
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo 'Please pass a source package name as the first argument.' >&2
    exit 1
fi
package="$1"
versions=$(curl -s "https://sources.debian.org/api/src/$package/")

if [ "$(echo "$versions" | jq '.error != null')" = 'true' ]; then
    echo "That package does not exists in the Debian sid source repositories: '$package'." >&2
    exit 1
fi

version=$(echo "$versions" | jq -r '.versions[] | select(any(.suites[]; . == "sid")) | first(.version)')

control_path=$(curl -s "https://sources.debian.org/api/src/$package/$version/debian/control/" | jq -r '.raw_url')

curl -s "https://sources.debian.org/$control_path"
