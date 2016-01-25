#!/bin/bash

set -ev

LUAROCKS_FOLDER="luarocks-2.3.0"
LUAROCKS_TARBALL="$LUAROCKS_FOLDER.tar.gz"

curl -O "http://keplerproject.github.io/luarocks/releases/$LUAROCKS_TARBALL"
tar zxf "$LUAROCKS_TARBALL"
cd "$LUAROCKS_FOLDER"
./configure --prefix="$HOME" --lua-version="$LUA_VERSION"
make build
make install
cd ..
rm -rf "$LUAROCKS_FOLDER"
