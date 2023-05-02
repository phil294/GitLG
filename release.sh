#!/bin/bash
set -e
set -o pipefail

pause() {
	read -r -n 1 -s -p 'Press any key to continue. . .'
	echo
}

git fetch
changes=$(git log --reverse origin/master.. --pretty=format:"%h___%B" |grep . |sed -E 's/^([0-9a-f]{6,})___(.)/- [`\1`](https:\/\/github.com\/phil294\/git-log--graph\/commit\/\1) \U\2/' ||:)

echo 'CHANGES, generated from commits since last git push:'
echo "$changes"
echo "---- (put into clipboard)"
echo "$changes" |xclip -sel c
echo 'update changelog'
pause

echo 'set package.json version'
pause

yarn
yarn coffee -c src/*.coffee
pushd web
yarn build
popd
rm web-dist/index.html

rm -rf node_modules
# TODO: instead, package properly (glob package) and then put node_modules on .vscodeignore again, as folder is too big
yarn install --production

# TODO: permission error postcss blah
# yarn upgrade
# pushd web
# yarn
# yarn upgrade
# popd
# git add yarn.lock
# git add web/yarn.lock
# git commit -m 'yarn upgrade' ||:


echo 'clean up local files for vsix packaging'
pause
pause

npx vsce package

echo 'check vsix package'
pause
pause

npx vsce publish
echo 'vscd published.'

npx ovsx publish "$(ls -tr git-log--graph-*.vsix* |tail -1)" -p "$(cat ~/.open-vsx-access-token)"
echo 'ovsx published.'

git push origin master

yarn