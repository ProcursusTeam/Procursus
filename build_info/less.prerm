#!/bin/sh

set -e

case "$1" in
  remove)
    update-alternatives --quiet --remove pager /usr/bin/less
  ;;
  upgrade|failed-upgrade|deconfigure)
  ;;
  *)
    echo "prerm called with unknown argument \`$1'" >&2
    exit 0
  ;;
esac



exit 0
