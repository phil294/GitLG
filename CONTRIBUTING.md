## Architecture

This extension is written in JavaScript with static type checking using [Typescript's flavor of JSDoc](https://www.typescriptlang.org/docs/handbook/jsdoc-supported-types.html). If you submit a PR, please make sure to install ESLint VSCode extension and make sure you see no errors in your code, reported neither by ESLint nor TypeScript.

The web part is written in [Vue.js 3](https://vuejs.org/guide/introduction.html) (composition API), also using JS/JSDoc. The only other external dependency is [`vue-virtual-scroller`](https://github.com/Akryum/vue-virtual-scroller/tree/next/packages/vue-virtual-scroller).

There is both a bootstrapping backend `extension.js` and a [webview](https://code.visualstudio.com/api/extension-guides/webview) which communicates with the backend via `bridge.js`. Git commands are implemented as a `git` child process in the backend. This way, web components are fully privileged via import, e.g.
```js
import { git } from 'bridge.js'
data = await git('show HEAD')
```
is all that is necessary.

All the interesting stuff happens inside `web/src/views`:
- `GitInput` handles all Git invoking logic (args, params etc. and save/reset)
- `CommitDetails` shows the stuff in the right box including commit/branch/stash actions
- `MainView` handles the left box including state, scrolling, searching, commit stats and global actions. Should probably be split in separate files
- The actual branch graph characters like `|/ / * |` are parsed in `log-utils` and later displayed in `SVGVisualization`. Also maybe see #22. Because of this, there is no necessity for individual graph construction logic which takes away a *lot* of complexity.

## Building

- First, once run `yarn install` both in the main and in the `web` subfolder (or `npm i`).
- Inside the web folder, run `yarn serve`. This runs the web app part at `http://localhost:8080` which we will access from the extension.
- Launch the script `Run Extension`.

This setup supports Vue's hot module replacement (HMR), so you normally do *not* have to restart anything while editing web files: Changes are immediately reflected in the extension's interface, allowing for rapid feedback.

To create a final `.vsix` production extension file, please refer to `./release.sh`.

Note that both source maps and minification are entirely disabled both in development and production as this results in a better runtime debugging experience and readability overall (no babel).
