#!/bin/bash
set -e
set -o pipefail

pause() {
	read -r -n 1 -s -p 'Press any key to continue. . .'
	echo
}

git fetch
changes=$(git log --reverse origin/master.. --pretty=format:"%h___%B" |grep . |sed -E 's/^([0-9a-f]{6,})___(.)/- [`\1`](https:\/\/github.com\/phil294\/git-log--graph\/commit\/\1) \U\2/')

echo 'CHANGES, generated from commits since last git push:'
echo "$changes"
echo "---- (put into clipboard)"
echo "$changes" |xclip -sel c
echo 'update changelog & set package.json version'
pause

yarn
yarn upgrade
pushd web
yarn
yarn upgrade
popd
git add yarn.lock
git add web/yarn.lock
git commit -m 'yarn upgrade' ||:

./build.sh
rm web-dist/index.html

npx vsce package

npx vsce publish

npx ovsx publish "$(ls -tr git-log--graph-*.vsix* |tail -1)" -p "$(cat ~/.open-vsx-access-token)"

git push origin master