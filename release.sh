#!/bin/bash
set -e
set -o pipefail

pause() {
    read -r -n 1 -s -p 'Press any key to continue. . .'
    echo
}
on_close() {
    echo "module.exports = require('./src/extension')" > main.js # revert
}
trap on_close EXIT

echo update readme
pause

if ! [ -z "$(git status --porcelain)" ]; then
    echo 'git working tree not clean'
    exit 1
fi

git push --tags origin master --dry-run

if grep -R -n -E '\s$' src web/src; then
    echo 'trailing whitespace found'
    exit 1
fi


: ''
npx ncu -u -x '@types/vscode'
npm i
pushd web
npx ncu -u
npm i
popd
git add package.json
git add package-lock.json
git add web/package.json
git add web/package-lock.json
git commit -m 'dependencies upgrade' ||:
echo 'deps upgraded'
pause
# '

pushd web
npm run build
popd
rm web-dist/index.html

echo -e '\nBuilding main bundle:'
npx esbuild src/extension.js --bundle --platform=node --outfile=main.js --external:vscode

echo built. manual tests:
pause

GIT_LOG__GRAPH_MODE=production vscodium --extensionDevelopmentPath="$PWD" --disable-extensions
pause
pause

git fetch
changes=$(git log --reverse "$(git describe --tags --abbrev=0)".. --pretty=format:"%h___%B" |grep . |sed -E 's/^([0-9a-f]{6,})___(.)/- [`\1`](https:\/\/github.com\/phil294\/GitLG\/commit\/\1) \U\2/')

echo edit changelog
pause
changes=$(micro <<< "$changes")
[ -z "$changes" ] && exit 1
echo changes:
echo "$changes"

version=$(npm version patch --no-git-tag-version)
echo version: $version
pause

sed -i $'/<!-- CHANGELOG_PLACEHOLDER -->/r'<(echo $'\n### '${version} $(date +"%Y-%m-%d")$'\n\n'"$changes") CHANGELOG.md

git add README.md
git add CHANGELOG.md
git add package.json
git commit -m "$version"
git tag "$version"
echo 'patched package.json version patch, updated changelog, committed, tagged'
pause

npx vsce package
vsix_file=$(ls -tr git-log--graph-*.vsix* |tail -1)
mv "$vsix_file" vsix-out/"$vsix_file"
vsix_file=vsix-out/"$vsix_file"
echo $vsix_file

xdg-open "$vsix_file"
ls -hltr vsix-out
ls -hltr
echo 'check vsix package before publish'
pause
pause

npx vsce publish
echo 'vsce published'
pause

npx ovsx publish "$vsix_file" -p "$(cat ~/.open-vsx-access-token)"
echo 'ovsx published'
pause

git push --tags origin master

if [[ -z $version || -z $changes || -z $vsix_file ]]; then
    echo version/changes empty
    exit 1
fi
echo 'will create github release'
pause
gh release create "$version" --target master --title "$version" --notes "$changes" --verify-tag "$vsix_file"
echo 'github release created'