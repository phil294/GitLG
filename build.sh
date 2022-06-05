#!/bin/bash
set -e
yarn coffee -c src/*.coffee
pushd web
yarn build "$@"
popd