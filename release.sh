#!/bin/bash
set -e
set -o pipefail

pause() {
    read -r -n 1 -s -p 'Press any key to continue. . .'
    echo
}

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

npx esbuild src/extension.js --bundle --platform=node --outfile=src/extension.js --allow-overwrite --external:vscode

echo built
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

npx vsce package

vsix_file=$(ls -tr git-log--graph-*.vsix* |tail -1)
xdg-open "$vsix_file"
echo 'check vsix package before publish'
ls -hltr
pause
pause

npx vsce publish
echo 'vsce published'
pause

npx ovsx publish "$vsix_file" -p "$(cat ~/.open-vsx-access-token)"
echo 'ovsx published'
pause

git push --tags origin master

echo 'will create github release'
pause
gh release create "$version" --target master --title "$version" --notes "$changes" --verify-tag
echo 'github release created'