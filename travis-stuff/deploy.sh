#!/bin/bash

set -ev

sed -i "s/##__TAG__##/$TRAVIS_TAG/" "$ROCKSPEC"

luarocks upload --api-key="$LUAROCKS_API_KEY" "$ROCKSPEC"
