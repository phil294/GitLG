## Architecture

This extension is written in modern [CoffeeScript](https://coffeescript.org). You can get full IntelliSense in `.coffee` files by installing the extension [`phil294.coffeesense`](https://github.com/phil294/coffeesense/), also listed in `extensions.json`. The web part is written in [Vue.js](https://vuejs.org/guide/introduction.html) (composition API). The only other external dependency is [`vue-virtual-scroller`](https://github.com/Akryum/vue-virtual-scroller/tree/next/packages/vue-virtual-scroller).

All code should be type-safe by the use of JSDoc in block comments (`###* @type {...} ###` etc.).

There is both a bootstrapping backend `extension.coffee` and a [webview](https://code.visualstudio.com/api/extension-guides/webview) which communicates with the backend via `bridge.coffee`. Git commands are implemented as a `git` childprocess in the backend. This way, web components are fully privileged via import, e.g.
```coffee
import { git } from 'bridge.coffee'
data = await git 'show HEAD'
```
is all that is necessary.

All the interesting stuff happens inside `web/src/views`:
- `GitInput` handles all Git invoking logic (args, params etc. and save/reset)
- `SelectedCommit` shows the stuff in the right box including commit/branch/stash actions
- `MainView` handles the left box including state, scrolling, searching, commit stats and global actions. Should probably be split in separate files
- `log-utils` is the only slightly complicated module, responsible for parsing the output of `git log --graph ...` (especially the visualization chars like `|/ / * |`), issued by `MainView`. Because of this, there is no necessity for individual graph construction logic which takes away a *lot* of complexity.

## Building

- First, once run `yarn install` both in the main and in the `web` subfolder.
- Then run `yarn coffee -c src/*.coffee` once. You'll have to repeat this every time you change anything inside `/src` (currently only `extension.coffee`).
- Inside the web folder, run `yarn serve`. This runs the web app part at `http://localhost:8080` which we will access from the extension.
- Launch the script `Run Extension`.

This setup supports Vue's hot module replacement (HMR), so you normally do *not* have to restart anything while editing web files: Changes are immediately reflected in the extension's interface, allowing for rapid feedback.

To create a final `.vsix` production extension file, please refer to `./release.sh`.

Note that both source maps and minification are entirely disabled both in development and production as this results in a better runtime debugging experience and readability overall (no babel).