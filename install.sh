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
_prefix='/usr/local'
_confdir=''
_libdir=''
_execdir=''
_docdir=''

while test 0 -ne $#; do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $_thisbase [-u|-p|-c|-l|-e|-d]

 -u    : uninstall         (default: install)
 -p XX : set prefix to XX  (default: /usr/local)
 -c XX : set confdir to XX (default: /usr/local/etc)
 -l XX : set libdir to XX  (default: /usr/local/lib)
 -e XX : set execdir to XX (default: /usr/local/bin)
 -d XX : set docdir to XX  (default: /usr/local/share/doc/picotask)
EOF
            exit 0
            ;;
        -u)
            _uninstall=1
            shift
            ;;
        -p)
            _prefix="$(printf '%s\n' "$2" | sed -r -e '$ s:/+$::')"
            shift 2
            ;;
        -c)
            _confdir="$(printf '%s\n' "$2" | sed -r -e '$ s:/+$::')"
            shift 2
            ;;
        -l)
            _libdir="$(printf '%s\n' "$2" | sed -r -e '$ s:/+$::')"
            shift 2
            ;;
        -e)
            _execdir="$(printf '%s\n' "$2" | sed -r -e '$ s:/+$::')"
            shift 2
            ;;
        -d)
            _docdir="$(printf '%s\n' "$2" | sed -r -e '$ s:/+$::')"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf 'Unknown arg "%s"\n' "$1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done
if test -z "$_confdir"; then
    if test '/usr' = "$_prefix"; then
        _confdir='/etc'
    else
        _confdir="${_prefix}/etc"
    fi
fi
test -n "$_libdir" || _libdir="${_prefix}/lib"
test -n "$_execdir" || _execdir="${_prefix}/bin"
test -n "$_docdir" || _docdir="${_prefix}/share/doc/picotask"

if test 1 -eq $_uninstall; then
    rm -fv "${_confdir}/picotask.l"
    rm -fv "${_libdir}/libpicotask.l"
    rm -fv "${_execdir}/picotask"
    rm -fv "${_docdir}/TODO"
    rm -fv "${_docdir}/README.md"
    rm -fv "${_docdir}/COPYING"
    rmdir -v "$_docdir"
else
    _sed_string="
        s:__CONFDIR__:${_confdir}:g
        s:__LIBDIR__:${_libdir}:g
        s:__EXECDIR__:${_execdir}:g
        s:__DOCDIR__:${_docdir}:g
        s:__PREFIX__:${_prefix}:g
    "
    mkdir -vp "$_confdir" "$_libdir" "$_execdir" "$_docdir"
    cp -fv "${_thisdir}/COPYING" "${_docdir}/COPYING"
    cp -fv "${_thisdir}/README.md" "${_docdir}/README.md"
    cp -fv "${_thisdir}/TODO" "${_docdir}/TODO"
    sed -e "$_sed_string" "${_thisdir}/picotask" >"${_execdir}/picotask"
    printf 'copied "%s" to "%s"\n' "${_thisdir}/picotask" "${_execdir}/picotask" >&2
    sed -e "$_sed_string" "${_thisdir}/lib/libpicotask.l" >"${_libdir}/libpicotask.l"
    printf 'copied "%s" to "%s"\n' "${_thisdir}/lib/libpicotask.l" "${_libdir}/libpicotask.l" >&2
    sed -e "$_sed_string" "${_thisdir}/conf/picotask.l" >"${_confdir}/picotask.l"
    printf 'copied "%s" to "%s"\n' "${_thisdir}/conf/picotask.l" "${_confdir}/picotask.l" >&2
fi
