#!/usr/bin/env bash
# Copyright 2021 the aerpatch authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



# Constants.

_POSTREL=$1
if [ $# -lt 1 ]; then
	_POSTREL=0
fi
_VERSION="$(date -u +'%Y%m%d')-$_POSTREL"

_SCRIPT="$(realpath "$0")"

_PRJDIR="$(dirname "$_SCRIPT")"

_SRCDIR="$_PRJDIR/src/"

_BUILDDIR="$_PRJDIR/build"

_STAGEDIR_REL="aerpatch-$_VERSION"
_STAGEDIR="$_BUILDDIR/$_STAGEDIR_REL"

_PKGFILE="$_BUILDDIR/aerpatch-$_VERSION.tar.gz"

_GAMEDIR="$HOME/.local/share/Steam/steamapps/common/HyperLightDrifter"

_ORIGEXEC="HyperLightDrifter"
_MODEXEC="${_ORIGEXEC}Patched"
_EXECDIFF="${_ORIGEXEC}Diff"



# Prepare build dir.
rm -rf "$_BUILDDIR"
mkdir -p "$_BUILDDIR"

# Create checksum for original executable.
pushd "$_GAMEDIR" >/dev/null
sha256sum --tag "$_ORIGEXEC" >"$_BUILDDIR/$_ORIGEXEC.checksum.txt"
popd >/dev/null

# Get clean copy of original executable.
cp "$_GAMEDIR/$_ORIGEXEC" "$_BUILDDIR/$_MODEXEC"

# Patch executable.
r2 -nwqi "$_SRCDIR/patch.r2" "$_BUILDDIR/$_MODEXEC"

# Create checksum for patched executable.
pushd "$_BUILDDIR" >/dev/null
sha256sum --tag "$_MODEXEC" >"$_BUILDDIR/$_MODEXEC.checksum.txt"
popd >/dev/null

# Create diff file.
rsync --only-write-batch="$_BUILDDIR/$_EXECDIFF" "$_BUILDDIR/$_MODEXEC" "$_GAMEDIR/$_ORIGEXEC"

# Stage build.
mkdir -p "$_STAGEDIR"
cp -t "$_STAGEDIR" "$_BUILDDIR/$_EXECDIFF" "$_BUILDDIR/$_ORIGEXEC.checksum.txt" "$_BUILDDIR/$_MODEXEC.checksum.txt" "$_PRJDIR/AUTHORS.txt" "$_PRJDIR/LICENSE.txt" "$_PRJDIR/NOTICE.txt"

# Create VERSION.txt file.
echo "$_VERSION" >"$_STAGEDIR/VERSION.txt"

# Package build.
tar -C "$_BUILDDIR" -acf "$_PKGFILE" "$_STAGEDIR_REL"
