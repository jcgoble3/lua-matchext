#!/bin/bash

set -ev

sed -i "s/##__TAG__##/$TRAVIS_TAG/" "$ROCKSPEC"

# upload requires a JSON library
luarocks install lua-cjson

luarocks upload --api-key="$LUAROCKS_API_KEY" "$ROCKSPEC"
