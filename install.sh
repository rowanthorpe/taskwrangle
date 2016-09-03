#!/bin/sh

set -e

_this="$(readlink -e "$0")"
_thisdir="$(dirname "$_this")"
_thisbase="$(basename "$_this")"

_uninstall=0
case "$1" in
    -u)
        _uninstall=1
        shift
        ;;
esac

if test 1 -eq $_uninstall; then
    rm -fv "/usr/local/share/doc/picotask/README.md"
    rm -fv "/usr/local/share/doc/picotask/TODO"
    rm -fv "/etc/picotask.l"
    rm -fv "/usr/local/lib/libpicotask.l"
    rm -fv "/usr/local/bin/picotask"
    rmdir /usr/local/share/doc/picotask </dev/null >/dev/null 2>&1 || :
else
    mkdir -p /etc /usr/local/lib /usr/local/bin /usr/local/share/doc/picotask
    cp -fv "${_thisdir}/README.md" "/usr/local/share/doc/picotask/README.md"
    cp -fv "${_thisdir}/TODO" "/usr/local/share/doc/picotask/TODO"
    cp -fv "${_thisdir}/conf/picotask.l" "/etc/picotask.l"
    cp -fv "${_thisdir}/lib/libpicotask.l" "/usr/local/lib/libpicotask.l"
    cp -fv "${_thisdir}/picotask" "/usr/local/bin/picotask"
fi
