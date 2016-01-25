#!/bin/bash

set -ev

if [[ $TRAVIS_OS_NAME = linux ]]; then
    BUILD_TARGET=linux
elif [[ $TRAVIS_OS_NAME = osx ]]; then
    BUILD_TARGET=macosx
fi

LUA_FOLDER="lua-$LUA_VERSION.$LUA_POINT"
LUA_TARBALL="$LUA_FOLDER.tar.gz"

curl -O "http://www.lua.org/ftp/$LUA_TARBALL"
tar zxf "$LUA_TARBALL"
cd "$LUA_FOLDER"
make "$BUILD_TARGET"
make install INSTALL_TOP="$HOME"
cd ..
rm -rf "$LUA_FOLDER" "$LUA_TARBALL"
