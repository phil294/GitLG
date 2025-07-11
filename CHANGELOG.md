## Changelog

Entries usually sorted by importance.

<!-- CHANGELOG_PLACEHOLDER -->

### v0.1.33 2025-07-08

- [`2139102`](https://github.com/phil294/GitLG/commit/2139102) Fix opening the graph view from SCM repo icon (#152)

### v0.1.32 2025-07-07

- [`89f8cd7`](https://github.com/phil294/GitLG/commit/89f8cd7) Fix opening the graph view from SCM repo icon (#152)

### v0.1.31 2025-07-07

- [`89f8cd7`](https://github.com/phil294/GitLG/commit/89f8cd7) Fix opening the graph view from SCM repo icon (#152)

### v0.1.30 2025-07-04

- [`97b0ec7`](https://github.com/phil294/GitLG/commit/97b0ec7) Allow selecting repo when current saved path is invalid, even when there is only one to choose from (#147)

### v0.1.29 2025-07-03

- [`e599297`](https://github.com/phil294/GitLG/commit/e599297) Fix Windows repo path logic, broken since last week, fixes #147
- [`96f3692`](https://github.com/phil294/GitLG/commit/96f3692) Prevent duplicate log load at start if last search type was non-immediate (file content etc.)
- [`3744984`](https://github.com/phil294/GitLG/commit/3744984) Reapply "Escape spaces in `git-path` folder setting" (#135)

### v0.1.28 2025-06-30

- [`026f687`](https://github.com/phil294/GitLG/commit/026f687) Fix Windows build (#147)
- [`026f687`](https://github.com/phil294/GitLG/commit/026f687) Revert `Escape spaces in 'git-path' folder setting` (#147, #135). This means that the edge case of having spaces in a custom git path name is now temporarily broken again.
- [`65c9893`](https://github.com/phil294/GitLG/commit/65c9893) Open `Configure...` section automatically when an error occurs in there, and prevent disabling that section once main git log fails due to an internal error, so you can retry and/or click `Reset` (#147)

### v0.1.27 2025-06-30

- [`9618cf6`](https://github.com/phil294/GitLG/commit/9618cf6) All full-text search for file contents, file names, commit bodies
- [`3a93d57`](https://github.com/phil294/GitLG/commit/3a93d57) Fix inconsistent branch tip colors while preliminary loading, and fix bad branch names in view after clicking "Show branch"
- [`ac8a4e0`](https://github.com/phil294/GitLG/commit/ac8a4e0) Make context menu entries selectable by keyboard, once the menu has been revealed by right click
- [`488b043`](https://github.com/phil294/GitLG/commit/488b043) Prevent errors when user-set config values are in the wrong format
- [`596d4fa`](https://github.com/phil294/GitLG/commit/596d4fa) Use `--author-date-order` in preliminary loading so the initial loading state doesn't look very different from the final loaded state, provided you didn't change its args much
- [`a0cc4f8`](https://github.com/phil294/GitLG/commit/a0cc4f8) Show proper error message if git status fails
- [`5c83a3e`](https://github.com/phil294/GitLG/commit/5c83a3e) Internal: Add typechecking to build process. Thanks to @alexrecuenco

### v0.1.26 2025-06-24

see below

### v0.1.25 2025-06-24

Fix broken release
Will update this text later

### v0.1.24 2025-06-24

- [`7a2b7f6`](https://github.com/phil294/GitLG/commit/7a2b7f6) Fix checking out and deleting branches that contain slashes like `feature/xyz`. Minor downside: Remotes containing slashes aren't supported anymore, such as if your origin(!) is called `my/remote` (#37). Fixes #130, #140.
- [`9328848`](https://github.com/phil294/GitLG/commit/9328848) [`90447fd`](https://github.com/phil294/GitLG/commit/90447fd) Fix scrolling on MacOS
- [`0244ef7`](https://github.com/phil294/GitLG/commit/0244ef7) Fix various errors at startup in workspaces with multiple repositories by changing internal repo selection logic from index-based to path-based, and don't load data before the currently selected repo is made available by Git. (#93, #71)
- [`78fff49`](https://github.com/phil294/GitLG/commit/78fff49) Set `hide-sidebar-buttons` config option default TRUE. Barely anyone seems to actually needs the big ugly buttons there. Use right click context menu or reactivate in settings.
- [`6d17b7b`](https://github.com/phil294/GitLG/commit/6d17b7b) Always show commit details changes buttons (multi-diff, tree/list toggle), not just on hover (#139)
- [`adb10f8`](https://github.com/phil294/GitLG/commit/adb10f8) Make status bar blame text configurable (#137)
- [`015d17d`](https://github.com/phil294/GitLG/commit/015d17d) Fix clicking on renamed files in commit diff view, and improve styling for renamed files (#131)
- [`9f83a4f`](https://github.com/phil294/GitLG/commit/9f83a4f) Fix clicking on files in stash commit
- [`9f3c7c7`](https://github.com/phil294/GitLG/commit/9f3c7c7) Highlight current search text in commit subject, author, hash and refs. Not perfect as hidden text will not be highlighted and there's no indicator but pretty useful nevertheless. (#120)
- [`e3ca67d`](https://github.com/phil294/GitLG/commit/e3ca67d) Change default value of `disable-scroll-snapping` to `true`. Snapping barely provides any benefit anymore and hijacking user scroll events should really be avoided
- [`6b6bc65`](https://github.com/phil294/GitLG/commit/6b6bc65) Added -x to cherry pick (#145). Thanks @notPlancha!
- [`e71450a`](https://github.com/phil294/GitLG/commit/e71450a) Fix wrong order of repos in selection if multiple projects with same folder name are present. Also now sets shortest possible paths for dupe repo names, not the full path if avoidable.
- [`dba3344`](https://github.com/phil294/GitLG/commit/dba3344) Hide repo selection dropdown when there's only one (#132)
- [`d62a09b`](https://github.com/phil294/GitLG/commit/d62a09b) [`8667ebb`](https://github.com/phil294/GitLG/commit/8667ebb) [`72b2c68`](https://github.com/phil294/GitLG/commit/72b2c68) Edit Commit message: Pre-fill textarea with current message instead of "Subject / Body" placeholder text (#126)
- [`c9eb7aa`](https://github.com/phil294/GitLG/commit/c9eb7aa) Add new optional  actionparam option `readonly`, for places where multiple inputs can be confusing otherwise or can provoke accidental param deletion. For example, to create a new branch, you don't have to delete the old one from the input field anymore.
- [`f13b967`](https://github.com/phil294/GitLG/commit/f13b967) Add new `placeholder` field to action params
- [`c94d256`](https://github.com/phil294/GitLG/commit/c94d256) Keep branch tips visible in commit details even if hide-sidebar-buttons is true (#136)
- [`c502845`](https://github.com/phil294/GitLG/commit/c502845) Escape spaces in `git-path` folder setting (#135)
- [`9bf25b1`](https://github.com/phil294/GitLG/commit/9bf25b1) Loading state when starting or switching repos by opacity and disabling mouse events, and clear list of commits when switching repos (#121)
- [`a4ef3f2`](https://github.com/phil294/GitLG/commit/a4ef3f2) Show loading indicator while commit details files list is loading (#133)
- [`d647cf8`](https://github.com/phil294/GitLG/commit/d647cf8) Make graph colors configurable. New settings: `branch-colors`, `branch-color-strategy` and `branch-color-custom-mapping`. (#123)
- [`163d71f`](https://github.com/phil294/GitLG/commit/163d71f) Run preliminary log for quick view preload not just on startup but also on repo change. This makes the switching between repos almost instantaneous, regardless of how big they each might be
- [`042760e`](https://github.com/phil294/GitLG/commit/042760e) Disable switching repos while a repo is still loading
- [`37039da`](https://github.com/phil294/GitLG/commit/37039da) [`a770e46`](https://github.com/phil294/GitLG/commit/a770e46) [`36a9a61`](https://github.com/phil294/GitLG/commit/36a9a61) Make filter jump/filter toggle a checkbox, not radio, and save the value between restarts (#120)
- [`a99f959`](https://github.com/phil294/GitLG/commit/a99f959) Allow `\` and `"` in git action param values
- [`bf49b49`](https://github.com/phil294/GitLG/commit/bf49b49) Make it possible to individually hide the two status bar entries, start and blame info by giving them unique ID/names. Hide by right clicking.
- [`949ef7e`](https://github.com/phil294/GitLG/commit/949ef7e) [`4c435de`](https://github.com/phil294/GitLG/commit/4c435de) Fix some high contrast theme styles
- [`c69808c`](https://github.com/phil294/GitLG/commit/c69808c) Highlight refresh button after clicking "Show branch" or "File history" to better hint at the need to click refresh now.
- [`8411fc4`](https://github.com/phil294/GitLG/commit/8411fc4) Fix error when clicking the init commit
- [`a548329`](https://github.com/phil294/GitLG/commit/a548329) Change color of pure-icon-buttons from text-color to icon-color. Noticeable only in very few themes.
- [`8049e7d`](https://github.com/phil294/GitLG/commit/8049e7d) Fix commit selection positioning on auto scroll if `"details-panel-position": "right"`
- [`b21efac`](https://github.com/phil294/GitLG/commit/b21efac) Fix different cache keys for multiple configured actions with no title but icon. They overwrote each other before. This was most likely only noticeable if you had at least two non-immediate global actions with icon only configured
- [`0844649`](https://github.com/phil294/GitLG/commit/0844649) Prevent preliminary loading result to hide "normal" log result in case the repo is very small
- [`563b5c5`](https://github.com/phil294/GitLG/commit/563b5c5) Reduce bundle size by 100 KB
- Lots and lots of internal code clean up, type-safe, linting

### v0.1.23 2024-12-07

- [`6abeea9`](https://github.com/phil294/GitLG/commit/6abeea9) Thicker logo, prettier and more readable in editors (tabs). Thanks again to @dimateos! (#125)
- [`81c0d37`](https://github.com/phil294/GitLG/commit/81c0d37) Fix gaps in lines when a new branch starts (#116)
- [`6756115`](https://github.com/phil294/GitLG/commit/6756115) Fix search filter/jump radio buttons
- [`0c356d2`](https://github.com/phil294/GitLG/commit/0c356d2) Fix search filter regex option
- [`dce6bfe`](https://github.com/phil294/GitLG/commit/dce6bfe) Fix auto-focussing input fields on git action popup open
- [`de6118f`](https://github.com/phil294/GitLG/commit/de6118f) Make the context menus feel and behave more like VSCode and actual context menus. Now you can also navigate between menu entries with up/down keys. Thanks to @samfundev! (#115)
- [`6c20a4d`](https://github.com/phil294/GitLG/commit/6c20a4d) Fix selected commit info hover color. Thanks @samfundev (#115)
- [`c450d9c`](https://github.com/phil294/GitLG/commit/c450d9c) Add commit action "Copy hash" to clipboard (#113, #76)
- [`78d2c9d`](https://github.com/phil294/GitLG/commit/78d2c9d) Check out branch by double clicking it (#95)
- [`ba6f03a`](https://github.com/phil294/GitLG/commit/ba6f03a) Fix deleting remote branch that does not exist on the remote anymore (#98)
- [`eb9ebe5`](https://github.com/phil294/GitLG/commit/eb9ebe5) Respect git.path setting (#90)
- [`38c8bff`](https://github.com/phil294/GitLG/commit/38c8bff) Ensure unique names in the repository dropdown
- [`35aab9e`](https://github.com/phil294/GitLG/commit/35aab9e) Fix saving custom input action value for global actions (#98)
- [`d8d016a`](https://github.com/phil294/GitLG/commit/d8d016a) Fix jumping UI when horizontal space is scarce (#114)
- [`13095e2`](https://github.com/phil294/GitLG/commit/13095e2) Fix repo selection dropdown to always be single-line
- [`1f396d9`](https://github.com/phil294/GitLG/commit/1f396d9) Fix "no commits found" position and padding
- [`6c728d7`](https://github.com/phil294/GitLG/commit/6c728d7) Fix History button positioning, was one pixel 
off
- [`9889de1`](https://github.com/phil294/GitLG/commit/9889de1) Internal: Automatic QA checks for PRs. Thanks to @alexrecuenco!
- [`85a72ec`](https://github.com/phil294/GitLG/commit/85a72ec) Fix dev errors in hot reload (HMR)

### v0.1.22 2024-11-19

- [`f52512a`](https://github.com/phil294/GitLG/commit/f52512a) [`af8aa6d`](https://github.com/phil294/GitLG/commit/af8aa6d) Light mode support and misc improvements. Much more consistent UI now thanks to @samfundev! (#111)
- [`559feb4`](https://github.com/phil294/GitLG/commit/559feb4) [`59a6777`](https://github.com/phil294/GitLG/commit/59a6777) Improve log parser. Outputs pretty similar graphs but less bugs and the internal logic is a bit different now. Also performance improvements, now about twice as fast than before
- [`29277bb`](https://github.com/phil294/GitLG/commit/29277bb) [`c3ca376`](https://github.com/phil294/GitLG/commit/c3ca376) Improve stats querying performance (insertions/deletions/files changed). Fixes immense lags for repos with very large files in its commits. Now first only the "files changed" amount is queried and the additions/deletions fixed after, with an upper limit on how many will be calculated in parallel.  Reason being that the insertions/deletions aren't cached by Git so it needs to read through the entire commit files. Stats can also now be disabled entirely.
- [`25769b7`](https://github.com/phil294/GitLG/commit/25769b7) Vastly improve scrolling performance by adding a 50 ms debounce
- [`215bcad`](https://github.com/phil294/GitLG/commit/215bcad) [`9b5a5e7`](https://github.com/phil294/GitLG/commit/9b5a5e7) Improve time to paint by showing the first 100 commits immediately after load, and parsing the rest (default: 15,000) afterward. This behavior can be disabled with `"git-log--graph.disable-preliminary-loading": true`
- [`9d846f2`](https://github.com/phil294/GitLG/commit/9d846f2) Fix freeze / keep the UI responsive while processing the git data on startup, after refresh or after any action run
- [`13e12a9`](https://github.com/phil294/GitLG/commit/13e12a9) Fix duplicate commit stats loading. Was heavy on performance
- [`d880d44`](https://github.com/phil294/GitLG/commit/d880d44) Blame: Allow jumping to commit even if it isn't currently loaded in the main view. In this case, GitLG will temporarily load the commits around the respective hash. Undo by clicking reload button. Also shows a popup to the user explaining what just happened.
- [`ba8b688`](https://github.com/phil294/GitLG/commit/ba8b688) Allow jumping to branch even if it isn't currently loaded in the main view. Like blame
- [`925c79c`](https://github.com/phil294/GitLG/commit/925c79c) Fix blame when switching between editors, no long necessary to type something to get the blame command to work

- [`eac3404`](https://github.com/phil294/GitLG/commit/eac3404) Fix ordering of branches in "all branches": Local ones first, even if they contain a `/` slash
- [`85b49d8`](https://github.com/phil294/GitLG/commit/85b49d8) Always keep selected commit centered while filtering. Previously it was only kept when you pressed the X clear button, now it aggressively jumps back to it

- [`aa143ce`](https://github.com/phil294/GitLG/commit/aa143ce) [`54a367a`](https://github.com/phil294/GitLG/commit/54a367a) Fix row-gaps in graph lines
- [`e80a225`](https://github.com/phil294/GitLG/commit/e80a225) Add Vue file type in diff list
- [`e899469`](https://github.com/phil294/GitLG/commit/e899469) Add animation while refreshing
- [`a410127`](https://github.com/phil294/GitLG/commit/a410127) Fix merge commit rendering in parallel branch scenarios `|\|` (#106)
- [`7b1f89e`](https://github.com/phil294/GitLG/commit/7b1f89e) Show commit index in commit details
- [`a91c0e8`](https://github.com/phil294/GitLG/commit/a91c0e8) Fix wrong graph line color right below merge commits originating form inferred branches
- [`6593dad`](https://github.com/phil294/GitLG/commit/6593dad) Fix highlighting current HEAD after checking out a remote branch with -b for which there is another branch with the same name
- [`7a70695`](https://github.com/phil294/GitLG/commit/7a70695) Fix duplicate branches / HEADs in exotic cases such as a *local* branch name such as `origin/my-branch` which would be duplicate with remote=origin and name=my-branch. Added `{BRANCH_ID}` and `{BRANCH_DISPLAY_NAME}` magic vars to git action parameter parsing
- [`69d19d2`](https://github.com/phil294/GitLG/commit/69d19d2) Prevent `(HEAD detached at [hash])` from showing up in branch listing
- [`0822080`](https://github.com/phil294/GitLG/commit/0822080) Change position of "Loading...". Now in status box instead above everything else. So no more vertical jumping after initial load
- [`64edf8e`](https://github.com/phil294/GitLG/commit/64edf8e) Make all params in git commands required

### v0.1.21 2024-10-04

fix bad release

### v0.1.20 2024-10-03

- [`c85b4bb`](https://github.com/phil294/GitLG/commit/c85b4bb) Add multi-diff viewer button to commit file changes (#83)
- [`00dfc90`](https://github.com/phil294/GitLG/commit/00dfc90) Fix missing display of merge commit lines in parallel branches (#106)
- [`3136e36`](https://github.com/phil294/GitLG/commit/3136e36) Fix wrong positioning of branch birth lines. Now they properly start *with* their birth commit, not before. (#81)
- [`39c7b7b`](https://github.com/phil294/GitLG/commit/39c7b7b) Merge commit lines into the merge commit circle, not the line below (#81)
- [`acfe462`](https://github.com/phil294/GitLG/commit/acfe462) Fix the small subtle gaps in graph lines between all lines. The thickness is now constant
- [`d023633`](https://github.com/phil294/GitLG/commit/d023633) Fix error when navigating to a file in deleted state (#109)
- [`c49060c`](https://github.com/phil294/GitLG/commit/c49060c) Fix layout of commit changes icons
- [`303ae55`](https://github.com/phil294/GitLG/commit/303ae55) Fix proper display of git error messages in two-step actions such as branch drop merge
- [`111e325`](https://github.com/phil294/GitLG/commit/111e325) Improve error message when the main LOG action fails (#108)

### v0.1.19 2024-10-01

- [`8ec690e`](https://github.com/phil294/GitLG/commit/8ec690e) Fix cryptic errors like `ENOENT 'C:\c:\...` on Windows. This happened when navigating files, as the "GitLG: Blame" command would not work anymore. Thanks to @GaryOma for ths fix

### v0.1.18 2024-09-30

- [`ea9da60`](https://github.com/phil294/GitLG/commit/ea9da60) Fix missing graph lines for some merge commits (#105, #106). In particular, if the first commit of said graph line has a branch tip to it *and* that branch id's name does not exactly match the subject of its merge commit.

### v0.1.17 2024-09-30

- [`234944a`](https://github.com/phil294/GitLG/commit/234944a) Fix bad positioning of loading message once the view has initialized
- [`8d97dc4`](https://github.com/phil294/GitLG/commit/8d97dc4) Fix file commit file listing for commits that have no parent
- [`bb9856d`](https://github.com/phil294/GitLG/commit/bb9856d) Fix "Open file" from within commit file changes in multi-repo scenarios. Sometimes the wrong repo was assumed, leading to a wrong or non-found opened file path
idk

### v0.1.16 2024-09-29

- [`794cf93`](https://github.com/phil294/GitLG/commit/794cf93) Rename the project to GitLG. Commented in #104
- Lots of internal code rework - removed preprocessors (no more CoffeeScript, SLM or Stylus), dependencies, error handling, refactoring, only thing remaining now is native web technologies + Vue.js. This should lower the barrier for making a PR.
- [`86de101`](https://github.com/phil294/GitLG/commit/86de101) Rework CONTRIBUTING.md
- [`488ca68`](https://github.com/phil294/GitLG/commit/488ca68) Move ref tips from graph area to in front of commit subject
This only shows in detached head state
- [`5452998`](https://github.com/phil294/GitLG/commit/5452998) Group local branch tip with its remotes into one bubble if they are on the same commit. Only if it's safe to do so, i.e. there are no tags or stashes with the same name. Two remotes without the local one also won't be grouped. Grouping can be deactivated by setting `{ "git-log--graph.group-branch-remotes": false }`
- [`5ca896b`](https://github.com/phil294/GitLG/commit/5ca896b) Set RefTip max-width to 350px, and make RefTips and subjects fully visible by hovering the graph visualization and the RefTips, respectively.
In a future VSCode version, hovering the author name will also automatically work for revealing the full subject.
- [`2ca9714`](https://github.com/phil294/GitLG/commit/2ca9714) Set color of HEAD "branch" to `#FFF`
- [`610b2fe`](https://github.com/phil294/GitLG/commit/610b2fe) Prevent shrinking of commit stats
- [`08b094b`](https://github.com/phil294/GitLG/commit/08b094b) Files diff list: Show plus or trash icon if file was added or deleted in commit, respectively
- [`c5b67fb`](https://github.com/phil294/GitLG/commit/c5b67fb) Add missing file icons: powershell, rust, go
- [`dcb2464`](https://github.com/phil294/GitLG/commit/dcb2464) Add small prompt text while the webview is loading
- [`d496b43`](https://github.com/phil294/GitLG/commit/d496b43) Commit Details: Show tag descriptions even if `hide-sidebar-buttons` is active
- [`1cf38f0`](https://github.com/phil294/GitLG/commit/1cf38f0) Commit Details: Prevent color codes from appearing in tag name
- [`3357ee7`](https://github.com/phil294/GitLG/commit/3357ee7) Improve logging: timestamps
- [`9edb92f`](https://github.com/phil294/GitLG/commit/9edb92f) Fix artificial 150 ms delay for main view
- [`c9edac2`](https://github.com/phil294/GitLG/commit/c9edac2) Fix unnecessary horizontal scrollbar in main view
- [`2db30f6`](https://github.com/phil294/GitLG/commit/2db30f6) NPM Auto install in web folder
- [`f4c9d86`](https://github.com/phil294/GitLG/commit/f4c9d86) Change wording in paragraph about Git Graph extension

### v0.1.15 2024-04-17

- [`f9eaec1`](https://github.com/phil294/GitLG/commit/f9eaec1) Update logo. Thanks @dimateos! (#860
- [`3b58274`](https://github.com/phil294/GitLG/commit/3b58274) Add new default commit action: Edit message. Works also for older commits. Only works when your work tree is clean (no changed files). Only works when the selected commit is part of the current branch. Note: Deleting commit rewrites history and should be avoided if it was already pushed. (#87)
- [`6a800e4`](https://github.com/phil294/GitLG/commit/6a800e4) Add new default commit action: Delete commit. Same as above!
- [`eb724c8`](https://github.com/phil294/GitLG/commit/eb724c8) Add new *refresh* command so that refreshing by shortcut is possible (#89)
- [`865c413`](https://github.com/phil294/GitLG/commit/865c413) Change git push / pull icons: Finally, they look like they should. This is the third change within a year or so, but Microsoft has now released official icons for it.
- [`871c3e3`](https://github.com/phil294/GitLG/commit/871c3e3) Change git stash icons: Same thing
- [`f0c71bc`](https://github.com/phil294/GitLG/commit/f0c71bc) Add new setting `"git-log--graph.details-panel-position"`: Decide where the commit details should appear when you click a row in the main view (#86)
- [`23c3ca1`](https://github.com/phil294/GitLG/commit/23c3ca1) Add new tag action: Push
- [`7c52ad1`](https://github.com/phil294/GitLG/commit/7c52ad1) Add new tag action: Delete (Remote) (#88)
- [`4eb4612`](https://github.com/phil294/GitLG/commit/4eb4612) Add new dynamic param value `{DEFAULT_REMOTE_NAME}` for optional usage in any command args
- [`96d3208`](https://github.com/phil294/GitLG/commit/96d3208) Make git path configurable (#90)
- [`2facbb3`](https://github.com/phil294/GitLG/commit/2facbb3) Allow referencing params (`$1` etc.) multiple times in args
- [`0f50ba1`](https://github.com/phil294/GitLG/commit/0f50ba1) Allow specifying line breaks in params via `\n`. Probably only useful for the new editing commit messages feature
- [`d5a2d67`](https://github.com/phil294/GitLG/commit/d5a2d67) Allow multi-select of commits in Mac using Cmd instead of Ctrl (#79)
- [`a5e0cc0`](https://github.com/phil294/GitLG/commit/a5e0cc0) Fix displaying of error "Params cannot contain quotes or backslashes". Didn't show before, just threw unexpectedly
- [`c316f7e`](https://github.com/phil294/GitLG/commit/c316f7e) Fix error when any git command fails with an empty message
- [`8f7c816`](https://github.com/phil294/GitLG/commit/8f7c816) Make parser more fault-tolerant. This can help with exotic custom log args
- [`1b74535`](https://github.com/phil294/GitLG/commit/1b74535) Add `--follow` to file history so to also see renamed files
- [`fa400e3`](https://github.com/phil294/GitLG/commit/fa400e3) Update codicon dependency to allow for newer icons in actions

### v0.1.14 2024-02-24

- [`c4f8cba`](https://github.com/phil294/GitLG/commit/c4f8cba) Add new "Show file history" button to files in commit details: This is a convenience function for adding ` -- "the-file.name"` to the main log and clicking "execute". It doesn't stay permanently like that, just once, and after any other git action or clicking refresh, the full view is available again. It's not possible to do this via mouse click for *any* file, just those that are listed in a commit. For more exotic use cases, keep using the main log git input.
- [`46f1292`](https://github.com/phil294/GitLG/commit/46f1292) Add new branch action button (dropdown / action button): "SHOW" (makes the main view only show commits that are relevant to the branch). This is a convenience function for adding ` branch-name` to the main log. See "show file history"
- [`757f139`](https://github.com/phil294/GitLG/commit/757f139) Deterministic branch colors: so now no matter what you do, the color is fixed based on the name of the branch, not (seemingly) random anymore. Note: Certain branches like master or development continue to have a fixed one.
- [`834c87b`](https://github.com/phil294/GitLG/commit/834c87b) Show amount of changes after "Changes" in files diff view
- [`3cd04b2`](https://github.com/phil294/GitLG/commit/3cd04b2) Fix opening the right repository in SCM menu (#42)
- [`ee4c920`](https://github.com/phil294/GitLG/commit/ee4c920) Add "close" command and "toggle" command (#49)
- [`019b5ea`](https://github.com/phil294/GitLG/commit/019b5ea) Show long/full hash in commit details and hash hover, and allow filtering/searching by it (#68)
- [`8f2c4ea`](https://github.com/phil294/GitLG/commit/8f2c4ea) Blame action: Fix jumping to commit directly when main view is already open (#67)
- [`09978f5`](https://github.com/phil294/GitLG/commit/09978f5) Allow searching for tags and stashes: You search for exactly what you also see in the interface, so for example to see all tags, you can search for `tag:` (#69)
- [`5d38851`](https://github.com/phil294/GitLG/commit/5d38851) Add support for RegEx search: remembers state, and can be toggled via mouse or <kbd>Alt</kbd>+<kbd>R</kbd>. It would be nice to have the search widget look and behave exactly like VSCode's internal one, including reusing the overwritten keybindings, but too much effort for now
- [`0537999`](https://github.com/phil294/GitLG/commit/0537999) Allow for more flexible min/max width graph view resizing (#22)
- [`5c0484b`](https://github.com/phil294/GitLG/commit/5c0484b) Enable search with F3 and fix search layout overflow (#50)
- [`0ba9d21`](https://github.com/phil294/GitLG/commit/0ba9d21) Make side bar X close button visible again
- [`cf56983`](https://github.com/phil294/GitLG/commit/cf56983) Fix display of special characters / Chinese chars in file name listing in commit details view (#74)
- [`0fa76d9`](https://github.com/phil294/GitLG/commit/0fa76d9) Fix display of empty commits (#73)
- [`9b5115d`](https://github.com/phil294/GitLG/commit/9b5115d) Fix case sensitivity in search (#72)
- [`99bea47`](https://github.com/phil294/GitLG/commit/99bea47) Fix file name display in git status section (#74)
- [`d50729e`](https://github.com/phil294/GitLG/commit/d50729e) Prevent infinite output channel output and errors in dev tools when you click into the extension output pane
- [`a9e9abd`](https://github.com/phil294/GitLG/commit/a9e9abd) [`546d8d6`](https://github.com/phil294/GitLG/commit/546d8d6) Improve error message handling and mostly actually show them in the first place, fix showing the messages in all expected ways (#66)
- [`54c374e`](https://github.com/phil294/GitLG/commit/54c374e) Improve error message and add fix instructions for when you have edited your main log args and it fails (or an update broke it unexpectedly) (#66)
- [`010e48d`](https://github.com/phil294/GitLG/commit/010e48d) Improve available list of colors a bit. Still not particularly great though...

### v0.1.13 2023-12-01

- [`f8184f1 ff`](https://github.com/phil294/GitLG/commit/f8184f1) Change visualization logic: More smooth and curvy, and connection lines can now span multiple rows of git's original output. There are no more "empty" rows. The "curviness" is somewhat configurable with config `curve-radius`.
- [`71e03df`](https://github.com/phil294/GitLG/commit/71e03df) Add new expandable, interactive "History" area at the top left: Remembers your searches, commit clicks and run actions per repository.
- [`6c9b0af`](https://github.com/phil294/GitLG/commit/6c9b0af) Add new setting `show-inferred-quick-branch-tips`, default off. Shows branch tips of unavailable (deleted) branches in the dotted branch connection area above if they could be reconstructed based on their merge commit subject message.
- [`7593cbe`](https://github.com/phil294/GitLG/commit/7593cbe) Fix Windows compatibility (?) (#63)
- [`fc1937a`](https://github.com/phil294/GitLG/commit/fc1937a) Make branch area resizable by drag/drop on the ● symbols. No longer adjust to the amount of branches present ([`8cc62bb`](https://github.com/phil294/GitLG/commit/8cc62bb)) (#22).
- [`cc1238d`](https://github.com/phil294/GitLG/commit/cc1238d) Support git mailmap (#58)
- [`d2fa4b1`](https://github.com/phil294/GitLG/commit/d2fa4b1) Display dates in local timezone. Can be customized by changing `--date=iso-local` to `--date=iso` in the main view log command config. It may be necessary to reset&save said log cmd field now or else the dates will look not as pretty (#54)
- [`030de22`](https://github.com/phil294/GitLG/commit/030de22) Make row height configurable
- [`dbac930`](https://github.com/phil294/GitLG/commit/dbac930) Fix hiding gitlab-style merge commits when "hide merge commits" setting is active
- [`b70cab3`](https://github.com/phil294/GitLG/commit/b70cab3) Improve default icon for git stash and pop
- [`a144d11`](https://github.com/phil294/GitLG/commit/a144d11) Ignore `[color] diff = always` if set in user config. If this affected you (the extension just hadn't worked at all), you might have to click "Reset" and "Save" in the main view's configure box (`log` command). (#61)
- [`58c709d`](https://github.com/phil294/GitLG/commit/58c709d) Change "All Branches" button styling
- [`22021ba`](https://github.com/phil294/GitLG/commit/22021ba) Remember last selected commit when switching between repos of the same workspace

### v0.1.12 2023-07-31

- [`94e4805`](https://github.com/phil294/GitLG/commit/94e4805) Fix repeated invocations of auto-execute actions: they weren't auto-executing properly from the second time on
- [`9ac2817`](https://github.com/phil294/GitLG/commit/3e0063a) Prevent git actions (including main log view) from executing before its respective saved configuration has been loaded and applied (#48)
- [`1b73ebe`](https://github.com/phil294/GitLG/commit/1b73ebe) Prevent duplicate log execution at startup (#48)
- [`edf12fd`](https://github.com/phil294/GitLG/commit/edf12fd) Fix wrong selected repo at startup
- [`8c54e93`](https://github.com/phil294/GitLG/commit/8c54e93) Fix automatic repo selection when git submodules are involved (#42)
- [`254c8fd`](https://github.com/phil294/GitLG/commit/70088e5) Fix refreshing after stashing (#27)
- [`6dfe240`](https://github.com/phil294/GitLG/commit/6dfe240) Fix commit multi-select
- [`995ab86`](https://github.com/phil294/GitLG/commit/995ab86) Add optional --simplify-by-decoration to git log (#22)
- [`8efde3e`](https://github.com/phil294/GitLG/commit/8efde3e) Rename "Filter / Search" -> "Filter / Jump"
- [`3a0d7cd`](https://github.com/phil294/GitLG/commit/3a0d7cd) Fix image links in extension description
- [`8ca41b5`](https://github.com/phil294/GitLG/commit/837054b) Move changelog into CHANGELOG.md (#28)
- [`e549b07`](https://github.com/phil294/GitLG/commit/e549b07) Attach built `.vsix` file to each future github release so you can also manually download them
- [`e4efa2a`](https://github.com/phil294/GitLG/commit/e4efa2a) Don't throw errors for grafted branches that don't actually exist
- [`5bd6be8`](https://github.com/phil294/GitLG/commit/5bd6be8) Skip unneeded source files inside /src

### v0.1.11 2023-06-30

- [`582ed6f`](https://github.com/phil294/GitLG/commit/582ed6f) Fix git blame line no (#47)

### v0.1.10 2023-06-24

- [`7c17b30`](https://github.com/phil294/GitLG/commit/7c17b30) Fix icons (#41)
- [`781e6da`](https://github.com/phil294/GitLG/commit/781e6da) Fix git blame line if soft links are involved (#40)
- [`d955a87`](https://github.com/phil294/GitLG/commit/d955a87) Fix SCM menu submodule selection (#42)
- [`ecba6c8`](https://github.com/phil294/GitLG/commit/ecba6c8) Remove hover effect from empty lines (#43, #22)

### v0.1.9 2023-06-21

- [`59c407f`](https://github.com/phil294/GitLG/commit/59c407f) Add git blame functionality. Shown in three places: status bar, as a new command, and as context menu in editor. Will open up the result of git blame on the currently selected line. (#40)
- [`6dfe584`](https://github.com/phil294/GitLG/commit/6dfe584) [`2179e1f`](https://github.com/phil294/GitLG/commit/2179e1f) Add new icon to open graph view from SCM view. Thanks to @lens0021
- [`17bc0d7`](https://github.com/phil294/GitLG/commit/17bc0d7) Add `"git-log--graph.hide-sidebar-buttons": true` (#2)
- [`79eb04c`](https://github.com/phil294/GitLG/commit/79eb04c) Make the styling for currently checked out branch a bit more subtle (#28)
- [`1d59395`](https://github.com/phil294/GitLG/commit/1d59395) Move commit hash to the very end (#22)
- [`8abde36`](https://github.com/phil294/GitLG/commit/8abde36) Add small "scroll to top" button (#36)
- [`355b12e`](https://github.com/phil294/GitLG/commit/355b12e) Show parent commits at bottom of commit details (#39)
- [`ad04152`](https://github.com/phil294/GitLG/commit/ad04152) Remember selected commit(s) from last time and re-focus on startup, and scroll to first selected commit automatically
- [`ac40792`](https://github.com/phil294/GitLG/commit/ac40792) Fix popup close button (#30)
- [`aba640f`](https://github.com/phil294/GitLG/commit/aba640f) Reduce width of branches by 50% for very large repositories (many branches) (#22)
- [`c3cb6f3`](https://github.com/phil294/GitLG/commit/c3cb6f3) Add options `--no-ff` and `--squash` to branch drop merge action
- [`e611d4b`](https://github.com/phil294/GitLG/commit/e611d4b) Fix rare case of missing branch tips (#22)
- [`11a4674`](https://github.com/phil294/GitLG/commit/11a4674) Add a generous max-width to author field for cases where author name is insanely long (#22)
- [`a5c2e5a`](https://github.com/phil294/GitLG/commit/a5c2e5a) Improve author tooltip to show both name and email
- [`852315c`](https://github.com/phil294/GitLG/commit/852315c) Ignore clicks on filler rows (#22)
- [`056f249`](https://github.com/phil294/GitLG/commit/056f249) Fix "merge branch commits" option. Didn't consider GH PRs
- [`22aee98`](https://github.com/phil294/GitLG/commit/22aee98) For automatic scroll actions, scroll to middle instead of top
- [`08d5c84`](https://github.com/phil294/GitLG/commit/08d5c84) Fix rare error after removing a folder from workspace

### v0.1.8 2023-06-13



### v0.1.7 2023-06-13

- [`40ca14b`](https://github.com/phil294/GitLG/commit/40ca14b) Files listing: optionally show as tree. Can be toggled by clicking the respective icon, just like in normal vscode scm view (#8)
- [`04f7dcd`](https://github.com/phil294/GitLG/commit/04f7dcd) Files listing: Add basic set of icons (#8)
- [`4f04c78`](https://github.com/phil294/GitLG/commit/4f04c78) Hide remote branches: New quick option in the `Configure...` section on top (#17, #18)
- [`454be25`](https://github.com/phil294/GitLG/commit/454be25) Hide merge commits: New quick option in the `Configure...` section on top (#17)
- [`5c47b92`](https://github.com/phil294/GitLG/commit/5c47b92) Add `action.info` `action.option.info` fields for documentation around commands and options. The default actions were populated with help texts from `git help ...`. (#17)
- [`63adec8`](https://github.com/phil294/GitLG/commit/63adec8) Custom CSS with new option `git-log--graph.custom-css` (#16)
- [`415096f`](https://github.com/phil294/GitLG/commit/415096f) Ensure same color for same branch-name / origin/branch-name
- [`55e0d46`](https://github.com/phil294/GitLG/commit/55e0d46) Add buttons in the changed files section for "show rev" and "open file". Thanks to @lens0021
- [`cbe2c5a`](https://github.com/phil294/GitLG/commit/cbe2c5a) Fix branch visualization automatic width update (#10)
- [`c6521c5`](https://github.com/phil294/GitLG/commit/c6521c5) Fix coloring for light *high contrast* themes
- [`245115a`](https://github.com/phil294/GitLG/commit/245115a) Add branch action "Delete (Remote)" and move rebase before delete. "Delete (Remote)" is also shown for local branches out of simplicity (we don't discriminate between local branch actions and remote branch actions right now). Just like with Push/Pull, the remote name is inferred for both cases so it doesn't matter where you run it.
- [`76c60e1`](https://github.com/phil294/GitLG/commit/76c60e1) allow for old ascii visualization via setting
- [`9588225`](https://github.com/phil294/GitLG/commit/9588225) Fix "git-log--graph.folder" config setting
- [`ae939c0`](https://github.com/phil294/GitLG/commit/ae939c0) Remove the shadow of all-branches button. Thanks to @lens0021
- [`bfe75f6`](https://github.com/phil294/GitLG/commit/bfe75f6) File diff list: more detailed tooltip popup (insertions/deletions)
- [`d345a32`](https://github.com/phil294/GitLG/commit/d345a32) Clear output on empty log return, such as when adding `-- nonexisting/file` to the end of the log command. So far, it was just ignored, falsely seeming to result in the same result as the previously executed one
- [`a1373cf`](https://github.com/phil294/GitLG/commit/a1373cf) Expose some objects as extension api (undocumented). If you want you can now build another extension that requires this one and exposes a `git ...` execute action on the currently selected repository.

### v0.1.6 2023-05-21

- [`588832e`](https://github.com/phil294/GitLG/commit/588832e) Light theme support (#13, PR #14) thanks to @lens0021
- [`5d60bc8`](https://github.com/phil294/GitLG/commit/5d60bc8) Higher res logo
- [`d7b4d7e`](https://github.com/phil294/GitLG/commit/d7b4d7e) git push option `--set-upstream` default TRUE
- [`901b2cf`](https://github.com/phil294/GitLG/commit/901b2cf) Log errors also into the dedicated output channel
- [`fa7b557`](https://github.com/phil294/GitLG/commit/fa7b557) Fix pull/push on local branches, even if they don't have a remote configured yet. The most likely remote will be prefilled: remote name, tracking remote name or default remote.
- [`1940cfa`](https://github.com/phil294/GitLG/commit/1940cfa) Color subject text of merge commits grey
- [`112a67f`](https://github.com/phil294/GitLG/commit/112a67f) Focus scroller on startup so immediate keyboard scrolling is possible

### v0.1.5 2023-05-18

- [`c529816`](https://github.com/phil294/GitLG/commit/c529816) Fix file diff views (#12)
- [`656bb08`](https://github.com/phil294/GitLG/commit/656bb08) Fix context menus on branches on top of commit
- [`7d2e568`](https://github.com/phil294/GitLG/commit/7d2e568) Context menu (right click): run action on left mouse UP event, not just click (down+up), to align with how context menus typically work basically everywhere
- [`75f7c66`](https://github.com/phil294/GitLG/commit/75f7c66) Increase external change delay margin from 1500 ms to 4500 ms to hopefully stop unnecessary duplicate reloads from occurring for good
- [`b2174d0`](https://github.com/phil294/GitLG/commit/b2174d0) Don't refresh on external index or work tree changes in case the repository is very big, this could lead to unnecessary loading times as we don't really show index/worktree changes except the little grey status text at the start and this is acceptable given we're talking about external changes only
- [`9bd4fc7`](https://github.com/phil294/GitLG/commit/9bd4fc7) Small visual bug: don't paint dotted vertical branch connection lines on top of / connecting to horizontal vis lines ____

### 0.1.4 2023-05-17

- [`4ec22f1`](https://github.com/phil294/GitLG/commit/4ec22f1) Allow showing the interface in a side bar ("view") instead of as a tab ("editor") with new option `git-log--graph.position` (#11)
- [`4ec22f1`](https://github.com/phil294/GitLG/commit/4ec22f1) New option `git-log--graph.hide-quick-branch-tips` should you dislike the dotted branch lines at the top
- [`ee797d7`](https://github.com/phil294/GitLG/commit/ee797d7) Commit details: show file name before path (#8)
- [`a5cfa38`](https://github.com/phil294/GitLG/commit/a5cfa38) Detect new repos automatically as they are added, detect repos nested deeper than three folders, by depending on the (built-in) `vscode.git` extension
- [`a8c5397`](https://github.com/phil294/GitLG/commit/a8c5397) Fix actions for branch pull/push: Now the remote is specified automatically and new options were added (the same as for merge)
- [`a5cfa38`](https://github.com/phil294/GitLG/commit/a5cfa38) Fixes detection of working tree changes or head moves e.g. on `commit --amend` (#9)
- [`07a3b80`](https://github.com/phil294/GitLG/commit/07a3b80) Auto-focus the command input in arg-less commands. In arg commands, args were already focussed. Now, it should always be possible to quick execute a command window by pressing return.
- [`135f1fd`](https://github.com/phil294/GitLG/commit/135f1fd) Prevent multiple context menus at the same time (#10)
- [`68bfb81`](https://github.com/phil294/GitLG/commit/68bfb81) Options reordering
- [`a5cfa38`](https://github.com/phil294/GitLG/commit/a5cfa38) Add new `verbose-logging` option for message logging
- [`a5cfa38`](https://github.com/phil294/GitLG/commit/a5cfa38) Add new output channel for dedicated log output

### 0.1.3 2023-05-14
- [`2912c4a`](https://github.com/phil294/GitLG/commit/2912c4a) Keep extension open on vscode restart - so just like any other "editor" (tab), it will keep its position, pin status etc. Not the scroll position within the view though, as it doesn't seem like a good idea (?)
- [`0ab1161`](https://github.com/phil294/GitLG/commit/0ab1161) Fix merging a remote branch: Falsely tried to merge the local counterpart instead
- [`d030697`](https://github.com/phil294/GitLG/commit/d030697) Improve scroll snapping so it's less annoying (#7)
- [`1d020d5`](https://github.com/phil294/GitLG/commit/1d020d5) Make scroll snapping optional with new option `git-log--graph.disable-scroll-snapping` (#7)
- [`a7167ed`](https://github.com/phil294/GitLG/commit/a7167ed) Refresh main view on external changes, most notably when doing commits
- [`9d09389`](https://github.com/phil294/GitLG/commit/9d09389) Force single instance: Switches to previously opened instance when attempting to open twice
- [`a91d226`](https://github.com/phil294/GitLG/commit/a91d226) Make selected commit side bar's hash selectable again
- [`199da81`](https://github.com/phil294/GitLG/commit/199da81) Start up slightly later to not slow initial vscode startup down
- [`7d8214b`](https://github.com/phil294/GitLG/commit/7d8214b) Fix extension crash when folder loading took too long, and increase timeout for it from 200 to 2000ms
- [`da969db`](https://github.com/phil294/GitLG/commit/da969db) Folder detection fallback for when initial folder scan took too long (>2s)
- [`09211a0`](https://github.com/phil294/GitLG/commit/09211a0) Fix error message prompt on git log error

### 0.1.2 2023-05-11
- [`3024d97`](https://github.com/phil294/GitLG/commit/3024d97) Add status bar shortcut (#5), so now you can also click on the `Git Log` menu instead of running the command.
- [`bbbaa8f`](https://github.com/phil294/GitLG/commit/bbbaa8f) Fix diff view (was the wrong way left/right)
- [`a60712e`](https://github.com/phil294/GitLG/commit/a60712e) Fix checkout of remote branches. Now just checks out the local branch name instead which in modern Git actually creates a new local tracking branch beforehand named after the remote one if it didn't exist. In other words, checkout `origin/main` now does a checkout `main`.
- [`ed873f4`](https://github.com/phil294/GitLG/commit/ed873f4) Fix branch logic (coloring, searching etc) for when more than one branch is connected to a single commit
- [`73d086d`](https://github.com/phil294/GitLG/commit/73d086d) Fix closing the Selected Commit view by pressing the X button
- [`12d73e0`](https://github.com/phil294/GitLG/commit/12d73e0) Show loading animation while immediate actions load. So for example when you click "Fetch", you'll now see that something is happening when your network is slow and it's not possible to click it again while doing so.
- [`9ad180b`](https://github.com/phil294/GitLG/commit/9ad180b) Move ref tags like branch tips a bit closer to their respective commit circle
- [`883edd0`](https://github.com/phil294/GitLG/commit/883edd0) Bundle extension js with esbuild. This reduces final bundle size by about 80% (as it was in prior updates) as node_modules aren't shipped anymore

### 0.1.1 2023-05-02
- Fix extension startup

### 0.1.0 2023-05-02
- [`bff9e5c`](https://github.com/phil294/GitLG/commit/bff9e5c) Windows support added thanks to @iamfraggle [#4](https://github.com/phil294/git-log--graph/pull/4) 🎉 (this was part of 0.0.5 already but not in changelog before)
- [`6a9b422`](https://github.com/phil294/GitLG/commit/6a9b422) New SVG-based graph visualization and large interface and style overhaul. Tell me if you miss the previous one, we can make stuff configurable if necessary. Sorry for breaking your work flow, but this should be the last major UI/UX update forever.
- [`0a66679`](https://github.com/phil294/GitLG/commit/0a66679) Make branch and commit actions available via context menu too (right click)
- [`cda96c2`](https://github.com/phil294/GitLG/commit/cda96c2) Add folder selection dropdown
- [`fb04477`](https://github.com/phil294/GitLG/commit/fb04477) Allow selecting multiple commits at once and add multi-commit actions
- [`b27a345`](https://github.com/phil294/GitLG/commit/b27a345) Show selected-commit (right bar) only when a commit was clicked, and option to close by clicking either the X button or again on the same commit or by pressing Escape
- [`e0f1efe`](https://github.com/phil294/GitLG/commit/e0f1efe) Show status text when not scrolled down
- [`1a8f4a7`](https://github.com/phil294/GitLG/commit/1a8f4a7) Stable colors for master, main, development, develop, dev, stage and staging
- [`7af64c8`](https://github.com/phil294/GitLG/commit/7af64c8) Allow for drag/drop from/to all branch tips, regardless of where they are in the UI
- [`823c720`](https://github.com/phil294/GitLG/commit/823c720) Default actions: New: create tag, delete tag, pop stash, delete stash, branch stash move, merge commit, commits cherry-pick, commits revert. Change: pull/push from global to branches, change icons for stash and stash pop, merge branch add options --no-ff and --squash. New section: Tags, Commits (plural)
- [`32a68b7`](https://github.com/phil294/GitLG/commit/32a68b7) Make vscode config *extend* the default actions (global, branch etc.) instead of overwriting - so it's not necessary anymore to replicate all of them if you want to add a new one. Editing/removing default ones is not possible anymore now, this would require a new setting - seems pretty pointless though. You'll have to update your actions if this affects you.
- [`ade3b4b`](https://github.com/phil294/GitLG/commit/ade3b4b) New setting for configurable graph width, by default now auto calculated width
- [`ade3b4b`](https://github.com/phil294/GitLG/commit/ade3b4b) Detection of config change updates the UI immediately
- [`9f5ebe2`](https://github.com/phil294/GitLG/commit/9f5ebe2) Accept graph lines that do not end on a space
- [`c084983`](https://github.com/phil294/GitLG/commit/c084983) Show "Loading..." while initialization
- [`5724ab9`](https://github.com/phil294/GitLG/commit/5724ab9) Hide the 'refs/stash' branch, it's useless
- [`84a8949`](https://github.com/phil294/GitLG/commit/84a8949) Scroll to selected commit scroll pos by clicking the hash
- [`a2cc721`](https://github.com/phil294/GitLG/commit/a2cc721) Show tag details (body) in selected commit view
- [`9d49608`](https://github.com/phil294/GitLG/commit/9d49608) Base stash actions on STASH_NAME instead of COMMIT_HASH. You'll have to update your actions if this affects you
- [`cff03a1`](https://github.com/phil294/GitLG/commit/cff03a1) Remove accidental permanent `-u` in git stash
- [`7c55a51`](https://github.com/phil294/GitLG/commit/7c55a51) Add search instructions if selected
- [`a0c61ca`](https://github.com/phil294/GitLG/commit/a0c61ca) Fix git option migration bug
- [`22419cb`](https://github.com/phil294/GitLG/commit/22419cb) Make date/author-date/topo order a default option in git log
- [`2593ecc`](https://github.com/phil294/GitLG/commit/2593ecc) Change magic word in log action from `VSCode` and `stash_refs` to `{EXT_FORMAT}` and `{STASH_REFS}`. You will need to reset and save your git log configuration if you have changed it.
- [`03d5978`](https://github.com/phil294/GitLG/commit/03d5978) Git input: auto focus first param input

### 0.0.5 2023-01-16
- [`9a2c177`](https://github.com/phil294/GitLG/commit/9a2c177) Use vscode-codicons instead of unicode icons (#3)
- [`9ca9296`](https://github.com/phil294/GitLG/commit/9ca9296) Add default push and pull actions
- [`cbbd17c`](https://github.com/phil294/GitLG/commit/cbbd17c) Add `git rebase --abort` to the abort action
- [`9a821df`](https://github.com/phil294/GitLG/commit/9a821df) Fix git reset args


### 0.0.4 2022-10-12
- [`1496dac`](https://github.com/phil294/GitLG/commit/1496dac) Many style improvements
- [`1496dac`](https://github.com/phil294/GitLG/commit/1496dac) Filter now includes branch name of commit

### 0.0.3 2022-09-17
- [`8f9dfd4`](https://github.com/phil294/GitLG/commit/8f9dfd4) Add drag/drop for branches. These actions are also configurable. By default there's `merge` and `rebase`.
- [`90531ce`](https://github.com/phil294/GitLG/commit/90531ce) Highlight the HEAD branch all the time
- [`59b478d`](https://github.com/phil294/GitLG/commit/59b478d) When scrolling to branch tip, also select the respective commit
- [`8434cc4`](https://github.com/phil294/GitLG/commit/8434cc4) In stash commits, show untracked change files too
- [`836debd`](https://github.com/phil294/GitLG/commit/836debd) Add `git reset --merge` to the abort default action
- [`8c55bc2`](https://github.com/phil294/GitLG/commit/8c55bc2) Enforce/overwrite dark theme on everything. Native dark/light theme support would be better, but the easiest way forward to fix any remaining color issues.
- [`32e211a`](https://github.com/phil294/GitLG/commit/32e211a) Make git conflict message detection locale independent (hopefully)
- [`667fa11`](https://github.com/phil294/GitLG/commit/667fa11) Make the " (HEAD)" part clickable
- [`c861a8b`](https://github.com/phil294/GitLG/commit/c861a8b) Add a thin line below the nav bar in main view
- [`25a54bf`](https://github.com/phil294/GitLG/commit/25a54bf) Action configuration: Apply replacements to title and description also

### 0.0.2 2022-06-05
- [`ac6ceee`](https://github.com/phil294/GitLG/commit/ac6ceee) Set icon

### 0.0.1 2022-06-05