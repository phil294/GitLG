#!/bin/bash
set -e
set -o pipefail

pause() {
    read -r -n 1 -s -p 'Press any key to continue. . .'
    echo
}

echo update readme
pause

if ! [ -z "$(git status --porcelain)" ]; then
    echo 'git working tree not clean'
    exit 1
fi

if grep -R -n --exclude='*.js' -E '\s$' src web/src; then
    echo 'trailing whitespace found'
    exit 1
fi


# # Cannot upgrade deps currently, TODO: https://github.com/vuejs/vue-loader/issues/2044
# yarn upgrade
# pushd web
# yarn
# yarn upgrade
# popd
# git add yarn.lock
# git add package.json
# git add web/yarn.lock
# git add web/package.json
# git commit -m 'yarn upgrade' ||:
# echo yarn upgraded
# pause

yarn
yarn coffee -c src/*.coffee
pushd web
yarn build
popd
rm web-dist/index.html

yarn esbuild src/extension.js --bundle --platform=node --outfile=src/extension.js --allow-overwrite --external:vscode
mv src/extension.js .
rm src/*.js
mv extension.js src

echo built. manual tests:
pause

GIT_LOG__GRAPH_MODE=production vscodium --extensionDevelopmentPath="$PWD" --disable-extensions
pause
pause

git fetch
changes=$(git log --reverse "$(git describe --tags --abbrev=0)".. --pretty=format:"%h___%B" |grep . |sed -E 's/^([0-9a-f]{6,})___(.)/- [`\1`](https:\/\/github.com\/phil294\/git-log--graph\/commit\/\1) \U\2/')

echo edit changelog
pause
changes=$(micro <<< "$changes")
[ -z "$changes" ] && exit 1
echo changes:
echo "$changes"

version=$(npm version patch --no-git-tag-version)
echo version: $version
pause

sed -i $'/<!-- CHANGELOG_PLACEHOLDER -->/r'<(echo $'\n### '${version} $(date +"%Y-%m-%d")$'\n\n'"$changes") README.md

git add README.md
git add package.json
git commit -m "$version"
git tag "$version"
echo 'patched package.json version patch, updated changelog, committed, tagged'
pause

yarn vsce package --yarn
vsix_file=$(ls -tr git-log--graph-*.vsix* |tail -1)
mv "$vsix_file" vsix-out/"$vsix_file"
vsix_file=vsix-out/"$vsix_file"

xdg-open "$vsix_file"
ls -hltr
echo 'check vsix package before publish'
pause
pause

yarn vsce publish --yarn
echo 'vsce published'
pause

yarn ovsx publish "$vsix_file" -p "$(cat ~/.open-vsx-access-token)"
echo 'ovsx published'
pause

git push --tags origin master

if [[ -z $version || -z $changes ]]; then
    echo version/changes empty
    exit 1
fi
echo 'will create github release'
pause
gh release create "$version" --target master --title "$version" --notes "$changes" --verify-tag "$vsix_file"
echo 'github release created'