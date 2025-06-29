## Contributing

This extension is written in JavaScript with very strict static type checking using [Typescript's flavor of JSDoc](https://www.typescriptlang.org/docs/handbook/jsdoc-supported-types.html).

Before you submit a PR, please make sure to
- create an issue so we can prevent wasted efforts
- have no JS/TS errors in your code: Install Vue language tools VSCode extension when working in the web/ `.vue` files
- *not* include any `@ts-ignore`s or type casts (`/** @type {...} */ (value)` in JSDoc) in your code. There's almost always a better solution.
- have no ESLint errors/warnings etc. in your code: Install the ESLint VSCode extension to see them. This helps enforcing standard camel_case variable naming style, tabs indentation and so on. You might need to set the node version to a higher value than the default v18 shipped by VSCode, using something a setting along the lines of `"eslint.runtime": "/path/to/.nvm/versions/node/v22.17.0/bin/node"` and restart VSCode.
- have your code be high quality, i.e.
  1. the JS reads as close to common English as possible and uses no abbreviations, yet:
  1. [the less, the better](https://blog.codinghorror.com/the-best-code-is-no-code-at-all/) until there is [nothing left to take away](http://prettyprint.me/prettyprint.me/2009/10/02/the-joy-of-deleting-code/index.html)
  1. [good code usually doesn't need comments](https://blog.codinghorror.com/coding-without-comments)

The driving intention here is to foster a long-lived open source project that enables the rapid addition of new features yet naturally needs very little maintenance.

There are currently no automated tests.

The web part is written in [Vue.js 3](https://vuejs.org/guide/introduction.html), also using JS/JSDoc (no direct TS). New or refactored components should use [Composition API](https://vuejs.org/guide/extras/composition-api-faq.html) and [`<script setup>`](https://vuejs.org/api/sfc-script-setup). The only other external dependency is [`vue-virtual-scroller`](https://github.com/Akryum/vue-virtual-scroller/tree/next/packages/vue-virtual-scroller).

CSS: Current definition and state of CSS in components is messy and introducing something like [Tailwind CSS](https://tailwindcss.com/) would align with this project's philosophies pretty well. ([details](https://github.com/phil294/GitLG/issues/62#issuecomment-2028448964))

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
- The actual branch graph characters like `|/ / * |` are parsed in `log-parser` and later displayed in `SVGVisualization`. Also maybe see #22. Because of this, there is no necessity for individual graph construction logic which takes away a *lot* of complexity.

## Building

- First, once run `npm install`.
- Inside the web folder, run `npm run serve`. This runs the web app part at `http://localhost:5173` which we will access from the extension.
- Launch the script `Run Extension`.

This setup supports Vue's hot module replacement (HMR), so you normally do *not* have to restart anything while editing web files: Changes are immediately reflected in the extension's interface, allowing for rapid feedback.

To create a final `.vsix` production extension file, please refer to `./release.sh`.

Note that both source maps and minification are entirely disabled both in development and production as this results in a better runtime debugging experience and readability overall (no babel).

## Issues

Besides PRs, GitHub issues are valuable contributions and should always be encouraged.

Closing issues due to inactivity (e.g. stalebot, banning "necrobumping" et al.) [is ridiculous](https://news.ycombinator.com/item?id=39886195). There's no such thing as too many open issues.