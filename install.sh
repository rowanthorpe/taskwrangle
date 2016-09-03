#!/bin/sh

##    Copyright © 2016 Rowan Thorpe, initially based entirely on a "taskdb" demo-app
##    posted by Joe Bognor at http://picolisp.com/wiki/?taskdb on 24 August 2016, and
##    intended to develop extensively from there.
##
##    This file is part of Picotask.
##
##    Picotask is free software: you can redistribute it and/or modify
##    it under the terms of the GNU Affero General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    Picotask is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU Affero General Public License for more details.
##
##    You should have received a copy of the GNU Affero General Public License
##    along with Picotask.  If not, see <http://www.gnu.org/licenses/>.

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
    rm -fv "/etc/picotask.l"
    rm -fv "/usr/local/lib/libpicotask.l"
    rm -fv "/usr/local/bin/picotask"
    rm -fv "/usr/local/share/doc/picotask/TODO"
    rm -fv "/usr/local/share/doc/picotask/README.md"
    rm -fv "/usr/local/share/doc/picotask/COPYING"
    rmdir /usr/local/share/doc/picotask
else
    mkdir -p /etc /usr/local/lib /usr/local/bin /usr/local/share/doc/picotask
    cp -fv "${_thisdir}/COPYING" "/usr/local/share/doc/picotask/COPYING"
    cp -fv "${_thisdir}/README.md" "/usr/local/share/doc/picotask/README.md"
    cp -fv "${_thisdir}/TODO" "/usr/local/share/doc/picotask/TODO"
    cp -fv "${_thisdir}/picotask" "/usr/local/bin/picotask"
    cp -fv "${_thisdir}/lib/libpicotask.l" "/usr/local/lib/libpicotask.l"
    cp -fv "${_thisdir}/conf/picotask.l" "/etc/picotask.l"
fi
