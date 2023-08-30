#!/bin/bash
set -e
set -o pipefail

yarn
yarn coffee -c src/*.coffee
rm web-dist/index.html || true

yarn esbuild src/extension.js --bundle --platform=node --outfile=src/extension.js --allow-overwrite --external:vscode
mv src/extension.js .
rm src/*.js
mv extension.js src

yarn vsce package --yarn
