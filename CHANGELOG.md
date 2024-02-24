## Changelog

Entries usually sorted by importance.

<!-- CHANGELOG_PLACEHOLDER -->

### v0.1.14 2024-02-24

- [`c4f8cba`](https://github.com/phil294/git-log--graph/commit/c4f8cba) Add new "Show file history" button to files in commit details: This is a convenience function for adding ` -- "the-file.name"` to the main log and clicking "execute". It doesn't stay permanently like that, just once, and after any other git action or clicking refresh, the full view is available again. It's not possible to do this via mouse click for *any* file, just those that are listed in a commit. For more exotic use cases, keep using the main log git input.
- [`46f1292`](https://github.com/phil294/git-log--graph/commit/46f1292) Add new branch action button (dropdown / action button): "SHOW" (makes the main view only show commits that are relevant to the branch). This is a convenience function for adding ` branch-name` to the main log. See "show file history"
- [`757f139`](https://github.com/phil294/git-log--graph/commit/757f139) Deterministic branch colors: so now no matter what you do, the color is fixed based on the name of the branch, not (seemingly) random anymore. Note: Certain branches like master or development continue to have a fixed one.
- [`834c87b`](https://github.com/phil294/git-log--graph/commit/834c87b) Show amount of changes after "Changes" in files diff view
- [`3cd04b2`](https://github.com/phil294/git-log--graph/commit/3cd04b2) Fix opening the right repository in SCM menu (#42)
- [`ee4c920`](https://github.com/phil294/git-log--graph/commit/ee4c920) Add "close" command and "toggle" command (#49)
- [`019b5ea`](https://github.com/phil294/git-log--graph/commit/019b5ea) Show long/full hash in commit details and hash hover, and allow filtering/searching by it (#68)
- [`8f2c4ea`](https://github.com/phil294/git-log--graph/commit/8f2c4ea) Blame action: Fix jumping to commit directly when main view is already open (#67)
- [`09978f5`](https://github.com/phil294/git-log--graph/commit/09978f5) Allow searching for tags and stashes: You search for exactly what you also see in the interface, so for example to see all tags, you can search for `tag:` (#69)
- [`5d38851`](https://github.com/phil294/git-log--graph/commit/5d38851) Add support for RegEx search: remembers state, and can be toggled via mouse or <kbd>Alt</kbd>+<kbd>R</kbd>. It would be nice to have the search widget look and behave exactly like VSCode's internal one, including reusing the overwritten keybindings, but too much effort for now
- [`0537999`](https://github.com/phil294/git-log--graph/commit/0537999) Allow for more flexible min/max width graph view resizing (#22)
- [`5c0484b`](https://github.com/phil294/git-log--graph/commit/5c0484b) Enable search with F3 and fix search layout overflow (#50)
- [`0ba9d21`](https://github.com/phil294/git-log--graph/commit/0ba9d21) Make side bar X close button visible again
- [`cf56983`](https://github.com/phil294/git-log--graph/commit/cf56983) Fix display of special characters / Chinese chars in file name listing in commit details view (#74)
- [`0fa76d9`](https://github.com/phil294/git-log--graph/commit/0fa76d9) Fix display of empty commits (#73)
- [`9b5115d`](https://github.com/phil294/git-log--graph/commit/9b5115d) Fix case sensitivity in search (#72)
- [`99bea47`](https://github.com/phil294/git-log--graph/commit/99bea47) Fix file name display in git status section (#74)
- [`d50729e`](https://github.com/phil294/git-log--graph/commit/d50729e) Prevent infinite output channel output and errors in dev tools when you click into the extension output pane
- [`a9e9abd`](https://github.com/phil294/git-log--graph/commit/a9e9abd) [`546d8d6`](https://github.com/phil294/git-log--graph/commit/546d8d6) Improve error message handling and mostly actually show them in the first place, fix showing the messages in all expected ways (#66)
- [`54c374e`](https://github.com/phil294/git-log--graph/commit/54c374e) Improve error message and add fix instructions for when you have edited your main log args and it fails (or an update broke it unexpectedly) (#66)
- [`010e48d`](https://github.com/phil294/git-log--graph/commit/010e48d) Improve available list of colors a bit. Still not particularly great though...

### v0.1.13 2023-12-01

- [`f8184f1 ff`](https://github.com/phil294/git-log--graph/commit/f8184f1) Change visualization logic: More smooth and curvy, and connection lines can now span multiple rows of git's original output. There are no more "empty" rows. The "curviness" is somewhat configurable with config `curve-radius`.
- [`71e03df`](https://github.com/phil294/git-log--graph/commit/71e03df) Add new expandable, interactive "History" area at the top left: Remembers your searches, commit clicks and run actions per repository.
- [`6c9b0af`](https://github.com/phil294/git-log--graph/commit/6c9b0af) Add new setting `show-inferred-quick-branch-tips`, default off. Shows branch tips of unavailable (deleted) branches in the dotted branch connection area above if they could be reconstructed based on their merge commit subject message.
- [`7593cbe`](https://github.com/phil294/git-log--graph/commit/7593cbe) Fix Windows compatibility (?) (#63)
- [`fc1937a`](https://github.com/phil294/git-log--graph/commit/fc1937a) Make branch area resizable by drag/drop on the ● symbols. No longer adjust to the amount of branches present ([`8cc62bb`](https://github.com/phil294/git-log--graph/commit/8cc62bb)) (#22).
- [`cc1238d`](https://github.com/phil294/git-log--graph/commit/cc1238d) Support git mailmap (#58)
- [`d2fa4b1`](https://github.com/phil294/git-log--graph/commit/d2fa4b1) Display dates in local timezone. Can be customized by changing `--date=iso-local` to `--date=iso` in the main view log command config. It may be necessary to reset&save said log cmd field now or else the dates will look not as pretty (#54)
- [`030de22`](https://github.com/phil294/git-log--graph/commit/030de22) Make row height configurable
- [`dbac930`](https://github.com/phil294/git-log--graph/commit/dbac930) Fix hiding gitlab-style merge commits when "hide merge commits" setting is active
- [`b70cab3`](https://github.com/phil294/git-log--graph/commit/b70cab3) Improve default icon for git stash and pop
- [`a144d11`](https://github.com/phil294/git-log--graph/commit/a144d11) Ignore `[color] diff = always` if set in user config. If this affected you (the extension just hadn't worked at all), you might have to click "Reset" and "Save" in the main view's configure box (`log` command). (#61)
- [`58c709d`](https://github.com/phil294/git-log--graph/commit/58c709d) Change "All Branches" button styling
- [`22021ba`](https://github.com/phil294/git-log--graph/commit/22021ba) Remember last selected commit when switching between repos of the same workspace

### v0.1.12 2023-07-31

- [`94e4805`](https://github.com/phil294/git-log--graph/commit/94e4805) Fix repeated invocations of auto-execute actions: they weren't auto-executing properly from the second time on
- [`9ac2817`](https://github.com/phil294/git-log--graph/commit/3e0063a) Prevent git actions (including main log view) from executing before its respective saved configuration has been loaded and applied (#48)
- [`1b73ebe`](https://github.com/phil294/git-log--graph/commit/1b73ebe) Prevent duplicate log execution at startup (#48)
- [`edf12fd`](https://github.com/phil294/git-log--graph/commit/edf12fd) Fix wrong selected repo at startup
- [`8c54e93`](https://github.com/phil294/git-log--graph/commit/8c54e93) Fix automatic repo selection when git submodules are involved (#42)
- [`254c8fd`](https://github.com/phil294/git-log--graph/commit/70088e5) Fix refreshing after stashing (#27)
- [`6dfe240`](https://github.com/phil294/git-log--graph/commit/6dfe240) Fix commit multi-select
- [`995ab86`](https://github.com/phil294/git-log--graph/commit/995ab86) Add optional --simplify-by-decoration to git log (#22)
- [`8efde3e`](https://github.com/phil294/git-log--graph/commit/8efde3e) Rename "Filter / Search" -> "Filter / Jump"
- [`3a0d7cd`](https://github.com/phil294/git-log--graph/commit/3a0d7cd) Fix image links in extension description
- [`8ca41b5`](https://github.com/phil294/git-log--graph/commit/837054b) Move changelog into CHANGELOG.md (#28)
- [`e549b07`](https://github.com/phil294/git-log--graph/commit/e549b07) Attach built `.vsix` file to each future github release so you can also manually download them
- [`e4efa2a`](https://github.com/phil294/git-log--graph/commit/e4efa2a) Don't throw errors for grafted branches that don't actually exist
- [`5bd6be8`](https://github.com/phil294/git-log--graph/commit/5bd6be8) Skip unneeded source files inside /src

### v0.1.11 2023-06-30

- [`582ed6f`](https://github.com/phil294/git-log--graph/commit/582ed6f) Fix git blame line no (#47)

### v0.1.10 2023-06-24

- [`7c17b30`](https://github.com/phil294/git-log--graph/commit/7c17b30) Fix icons (#41)
- [`781e6da`](https://github.com/phil294/git-log--graph/commit/781e6da) Fix git blame line if soft links are involved (#40)
- [`d955a87`](https://github.com/phil294/git-log--graph/commit/d955a87) Fix SCM menu submodule selection (#42)
- [`ecba6c8`](https://github.com/phil294/git-log--graph/commit/ecba6c8) Remove hover effect from empty lines (#43, #22)

### v0.1.9 2023-06-21

- [`59c407f`](https://github.com/phil294/git-log--graph/commit/59c407f) Add git blame functionality. Shown in three places: status bar, as a new command, and as context menu in editor. Will open up the result of git blame on the currently selected line. (#40)
- [`6dfe584`](https://github.com/phil294/git-log--graph/commit/6dfe584) [`2179e1f`](https://github.com/phil294/git-log--graph/commit/2179e1f) Add new icon to open graph view from SCM view. Thanks to @lens0021
- [`17bc0d7`](https://github.com/phil294/git-log--graph/commit/17bc0d7) Add `"git-log--graph.hide-sidebar-buttons": true` (#2)
- [`79eb04c`](https://github.com/phil294/git-log--graph/commit/79eb04c) Make the styling for currently checked out branch a bit more subtle (#28)
- [`1d59395`](https://github.com/phil294/git-log--graph/commit/1d59395) Move commit hash to the very end (#22)
- [`8abde36`](https://github.com/phil294/git-log--graph/commit/8abde36) Add small "scroll to top" button (#36)
- [`355b12e`](https://github.com/phil294/git-log--graph/commit/355b12e) Show parent commits at bottom of commit details (#39)
- [`ad04152`](https://github.com/phil294/git-log--graph/commit/ad04152) Remember selected commit(s) from last time and re-focus on startup, and scroll to first selected commit automatically
- [`ac40792`](https://github.com/phil294/git-log--graph/commit/ac40792) Fix popup close button (#30)
- [`aba640f`](https://github.com/phil294/git-log--graph/commit/aba640f) Reduce width of branches by 50% for very large repositories (many branches) (#22)
- [`c3cb6f3`](https://github.com/phil294/git-log--graph/commit/c3cb6f3) Add options `--no-ff` and `--squash` to branch drop merge action
- [`e611d4b`](https://github.com/phil294/git-log--graph/commit/e611d4b) Fix rare case of missing branch tips (#22)
- [`11a4674`](https://github.com/phil294/git-log--graph/commit/11a4674) Add a generous max-width to author field for cases where author name is insanely long (#22)
- [`a5c2e5a`](https://github.com/phil294/git-log--graph/commit/a5c2e5a) Improve author tooltip to show both name and email
- [`852315c`](https://github.com/phil294/git-log--graph/commit/852315c) Ignore clicks on filler rows (#22)
- [`056f249`](https://github.com/phil294/git-log--graph/commit/056f249) Fix "merge branch commits" option. Didn't consider GH PRs
- [`22aee98`](https://github.com/phil294/git-log--graph/commit/22aee98) For automatic scroll actions, scroll to middle instead of top
- [`08d5c84`](https://github.com/phil294/git-log--graph/commit/08d5c84) Fix rare error after removing a folder from workspace

### v0.1.8 2023-06-13



### v0.1.7 2023-06-13

- [`40ca14b`](https://github.com/phil294/git-log--graph/commit/40ca14b) Files listing: optionally show as tree. Can be toggled by clicking the respective icon, just like in normal vscode scm view (#8)
- [`04f7dcd`](https://github.com/phil294/git-log--graph/commit/04f7dcd) Files listing: Add basic set of icons (#8)
- [`4f04c78`](https://github.com/phil294/git-log--graph/commit/4f04c78) Hide remote branches: New quick option in the `Configure...` section on top (#17, #18)
- [`454be25`](https://github.com/phil294/git-log--graph/commit/454be25) Hide merge commits: New quick option in the `Configure...` section on top (#17)
- [`5c47b92`](https://github.com/phil294/git-log--graph/commit/5c47b92) Add `action.info` `action.option.info` fields for documentation around commands and options. The default actions were populated with help texts from `git help ...`. (#17)
- [`63adec8`](https://github.com/phil294/git-log--graph/commit/63adec8) Custom CSS with new option `git-log--graph.custom-css` (#16)
- [`415096f`](https://github.com/phil294/git-log--graph/commit/415096f) Ensure same color for same branch-name / origin/branch-name
- [`55e0d46`](https://github.com/phil294/git-log--graph/commit/55e0d46) Add buttons in the changed files section for "show rev" and "open file". Thanks to @lens0021
- [`cbe2c5a`](https://github.com/phil294/git-log--graph/commit/cbe2c5a) Fix branch visualization automatic width update (#10)
- [`c6521c5`](https://github.com/phil294/git-log--graph/commit/c6521c5) Fix coloring for light *high contrast* themes
- [`245115a`](https://github.com/phil294/git-log--graph/commit/245115a) Add branch action "Delete (Remote)" and move rebase before delete. "Delete (Remote)" is also shown for local branches out of simplicity (we don't discriminate between local branch actions and remote branch actions right now). Just like with Push/Pull, the remote name is inferred for both cases so it doesn't matter where you run it.
- [`76c60e1`](https://github.com/phil294/git-log--graph/commit/76c60e1) allow for old ascii visualization via setting
- [`9588225`](https://github.com/phil294/git-log--graph/commit/9588225) Fix "git-log--graph.folder" config setting
- [`ae939c0`](https://github.com/phil294/git-log--graph/commit/ae939c0) Remove the shadow of all-branches button. Thanks to @lens0021
- [`bfe75f6`](https://github.com/phil294/git-log--graph/commit/bfe75f6) File diff list: more detailed tooltip popup (insertions/deletions)
- [`d345a32`](https://github.com/phil294/git-log--graph/commit/d345a32) Clear output on empty log return, such as when adding `-- nonexisting/file` to the end of the log command. So far, it was just ignored, falsely seeming to result in the same result as the previously executed one
- [`a1373cf`](https://github.com/phil294/git-log--graph/commit/a1373cf) Expose some objects as extension api (undocumented). If you want you can now build another extension that requires this one and exposes a `git ...` execute action on the currently selected repository.

### v0.1.6 2023-05-21

- [`588832e`](https://github.com/phil294/git-log--graph/commit/588832e) Light theme support (#13, PR #14) thanks to @lens0021
- [`5d60bc8`](https://github.com/phil294/git-log--graph/commit/5d60bc8) Higher res logo
- [`d7b4d7e`](https://github.com/phil294/git-log--graph/commit/d7b4d7e) git push option `--set-upstream` default TRUE
- [`901b2cf`](https://github.com/phil294/git-log--graph/commit/901b2cf) Log errors also into the dedicated output channel
- [`fa7b557`](https://github.com/phil294/git-log--graph/commit/fa7b557) Fix pull/push on local branches, even if they don't have a remote configured yet. The most likely remote will be prefilled: remote name, tracking remote name or default remote.
- [`1940cfa`](https://github.com/phil294/git-log--graph/commit/1940cfa) Color subject text of merge commits grey
- [`112a67f`](https://github.com/phil294/git-log--graph/commit/112a67f) Focus scroller on startup so immediate keyboard scrolling is possible

### v0.1.5 2023-05-18

- [`c529816`](https://github.com/phil294/git-log--graph/commit/c529816) Fix file diff views (#12)
- [`656bb08`](https://github.com/phil294/git-log--graph/commit/656bb08) Fix context menus on branches on top of commit
- [`7d2e568`](https://github.com/phil294/git-log--graph/commit/7d2e568) Context menu (right click): run action on left mouse UP event, not just click (down+up), to align with how context menus typically work basically everywhere
- [`75f7c66`](https://github.com/phil294/git-log--graph/commit/75f7c66) Increase external change delay margin from 1500 ms to 4500 ms to hopefully stop unnecessary duplicate reloads from occurring for good
- [`b2174d0`](https://github.com/phil294/git-log--graph/commit/b2174d0) Don't refresh on external index or work tree changes in case the repository is very big, this could lead to unnecessary loading times as we don't really show index/worktree changes except the little grey status text at the start and this is acceptable given we're talking about external changes only
- [`9bd4fc7`](https://github.com/phil294/git-log--graph/commit/9bd4fc7) Small visual bug: don't paint dotted vertical branch connection lines on top of / connecting to horizontal vis lines ____

### 0.1.4 2023-05-17

- [`4ec22f1`](https://github.com/phil294/git-log--graph/commit/4ec22f1) Allow showing the interface in a side bar ("view") instead of as a tab ("editor") with new option `git-log--graph.position` (#11)
- [`4ec22f1`](https://github.com/phil294/git-log--graph/commit/4ec22f1) New option `git-log--graph.hide-quick-branch-tips` should you dislike the dotted branch lines at the top
- [`ee797d7`](https://github.com/phil294/git-log--graph/commit/ee797d7) Commit details: show file name before path (#8)
- [`a5cfa38`](https://github.com/phil294/git-log--graph/commit/a5cfa38) Detect new repos automatically as they are added, detect repos nested deeper than three folders, by depending on the (built-in) `vscode.git` extension
- [`a8c5397`](https://github.com/phil294/git-log--graph/commit/a8c5397) Fix actions for branch pull/push: Now the remote is specified automatically and new options were added (the same as for merge)
- [`a5cfa38`](https://github.com/phil294/git-log--graph/commit/a5cfa38) Fixes detection of working tree changes or head moves e.g. on `commit --amend` (#9)
- [`07a3b80`](https://github.com/phil294/git-log--graph/commit/07a3b80) Auto-focus the command input in arg-less commands. In arg commands, args were already focussed. Now, it should always be possible to quick execute a command window by pressing return.
- [`135f1fd`](https://github.com/phil294/git-log--graph/commit/135f1fd) Prevent multiple context menus at the same time (#10)
- [`68bfb81`](https://github.com/phil294/git-log--graph/commit/68bfb81) Options reordering
- [`a5cfa38`](https://github.com/phil294/git-log--graph/commit/a5cfa38) Add new `verbose-logging` option for message logging
- [`a5cfa38`](https://github.com/phil294/git-log--graph/commit/a5cfa38) Add new output channel for dedicated log output

### 0.1.3 2023-05-14
- [`2912c4a`](https://github.com/phil294/git-log--graph/commit/2912c4a) Keep extension open on vscode restart - so just like any other "editor" (tab), it will keep its position, pin status etc. Not the scroll position within the view though, as it doesn't seem like a good idea (?)
- [`0ab1161`](https://github.com/phil294/git-log--graph/commit/0ab1161) Fix merging a remote branch: Falsely tried to merge the local counterpart instead
- [`d030697`](https://github.com/phil294/git-log--graph/commit/d030697) Improve scroll snapping so it's less annoying (#7)
- [`1d020d5`](https://github.com/phil294/git-log--graph/commit/1d020d5) Make scroll snapping optional with new option `git-log--graph.disable-scroll-snapping` (#7)
- [`a7167ed`](https://github.com/phil294/git-log--graph/commit/a7167ed) Refresh main view on external changes, most notably when doing commits
- [`9d09389`](https://github.com/phil294/git-log--graph/commit/9d09389) Force single instance: Switches to previously opened instance when attempting to open twice
- [`a91d226`](https://github.com/phil294/git-log--graph/commit/a91d226) Make selected commit side bar's hash selectable again
- [`199da81`](https://github.com/phil294/git-log--graph/commit/199da81) Start up slightly later to not slow initial vscode startup down
- [`7d8214b`](https://github.com/phil294/git-log--graph/commit/7d8214b) Fix extension crash when folder loading took too long, and increase timeout for it from 200 to 2000ms
- [`da969db`](https://github.com/phil294/git-log--graph/commit/da969db) Folder detection fallback for when initial folder scan took too long (>2s)
- [`09211a0`](https://github.com/phil294/git-log--graph/commit/09211a0) Fix error message prompt on git log error

### 0.1.2 2023-05-11
- [`3024d97`](https://github.com/phil294/git-log--graph/commit/3024d97) Add status bar shortcut (#5), so now you can also click on the `Git Log` menu instead of running the command.
- [`bbbaa8f`](https://github.com/phil294/git-log--graph/commit/bbbaa8f) Fix diff view (was the wrong way left/right)
- [`a60712e`](https://github.com/phil294/git-log--graph/commit/a60712e) Fix checkout of remote branches. Now just checks out the local branch name instead which in modern Git actually creates a new local tracking branch beforehand named after the remote one if it didn't exist. In other words, checkout `origin/main` now does a checkout `main`.
- [`ed873f4`](https://github.com/phil294/git-log--graph/commit/ed873f4) Fix branch logic (coloring, searching etc) for when more than one branch is connected to a single commit
- [`73d086d`](https://github.com/phil294/git-log--graph/commit/73d086d) Fix closing the Selected Commit view by pressing the X button
- [`12d73e0`](https://github.com/phil294/git-log--graph/commit/12d73e0) Show loading animation while immediate actions load. So for example when you click "Fetch", you'll now see that something is happening when your network is slow and it's not possible to click it again while doing so.
- [`9ad180b`](https://github.com/phil294/git-log--graph/commit/9ad180b) Move ref tags like branch tips a bit closer to their respective commit circle
- [`883edd0`](https://github.com/phil294/git-log--graph/commit/883edd0) Bundle extension js with esbuild. This reduces final bundle size by about 80% (as it was in prior updates) as node_modules aren't shipped anymore

### 0.1.1 2023-05-02
- Fix extension startup

### 0.1.0 2023-05-02
- [`bff9e5c`](https://github.com/phil294/git-log--graph/commit/bff9e5c) Windows support added thanks to @iamfraggle [#4](https://github.com/phil294/git-log--graph/pull/4) 🎉 (this was part of 0.0.5 already but not in changelog before)
- [`6a9b422`](https://github.com/phil294/git-log--graph/commit/6a9b422) New SVG-based graph visualization and large interface and style overhaul. Tell me if you miss the previous one, we can make stuff configurable if necessary. Sorry for breaking your work flow, but this should be the last major UI/UX update forever.
- [`0a66679`](https://github.com/phil294/git-log--graph/commit/0a66679) Make branch and commit actions available via context menu too (right click)
- [`cda96c2`](https://github.com/phil294/git-log--graph/commit/cda96c2) Add folder selection dropdown
- [`fb04477`](https://github.com/phil294/git-log--graph/commit/fb04477) Allow selecting multiple commits at once and add multi-commit actions
- [`b27a345`](https://github.com/phil294/git-log--graph/commit/b27a345) Show selected-commit (right bar) only when a commit was clicked, and option to close by clicking either the X button or again on the same commit or by pressing Escape
- [`e0f1efe`](https://github.com/phil294/git-log--graph/commit/e0f1efe) Show status text when not scrolled down
- [`1a8f4a7`](https://github.com/phil294/git-log--graph/commit/1a8f4a7) Stable colors for master, main, development, develop, dev, stage and staging
- [`7af64c8`](https://github.com/phil294/git-log--graph/commit/7af64c8) Allow for drag/drop from/to all branch tips, regardless of where they are in the UI
- [`823c720`](https://github.com/phil294/git-log--graph/commit/823c720) Default actions: New: create tag, delete tag, pop stash, delete stash, branch stash move, merge commit, commits cherry-pick, commits revert. Change: pull/push from global to branches, change icons for stash and stash pop, merge branch add options --no-ff and --squash. New section: Tags, Commits (plural)
- [`32a68b7`](https://github.com/phil294/git-log--graph/commit/32a68b7) Make vscode config *extend* the default actions (global, branch etc.) instead of overwriting - so it's not necessary anymore to replicate all of them if you want to add a new one. Editing/removing default ones is not possible anymore now, this would require a new setting - seems pretty pointless though. You'll have to update your actions if this affects you.
- [`ade3b4b`](https://github.com/phil294/git-log--graph/commit/ade3b4b) New setting for configurable graph width, by default now auto calculated width
- [`ade3b4b`](https://github.com/phil294/git-log--graph/commit/ade3b4b) Detection of config change updates the UI immediately
- [`9f5ebe2`](https://github.com/phil294/git-log--graph/commit/9f5ebe2) Accept graph lines that do not end on a space
- [`c084983`](https://github.com/phil294/git-log--graph/commit/c084983) Show "Loading..." while initialization
- [`5724ab9`](https://github.com/phil294/git-log--graph/commit/5724ab9) Hide the 'refs/stash' branch, it's useless
- [`84a8949`](https://github.com/phil294/git-log--graph/commit/84a8949) Scroll to selected commit scroll pos by clicking the hash
- [`a2cc721`](https://github.com/phil294/git-log--graph/commit/a2cc721) Show tag details (body) in selected commit view
- [`9d49608`](https://github.com/phil294/git-log--graph/commit/9d49608) Base stash actions on STASH_NAME instead of COMMIT_HASH. You'll have to update your actions if this affects you
- [`cff03a1`](https://github.com/phil294/git-log--graph/commit/cff03a1) Remove accidental permanent `-u` in git stash
- [`7c55a51`](https://github.com/phil294/git-log--graph/commit/7c55a51) Add search instructions if selected
- [`a0c61ca`](https://github.com/phil294/git-log--graph/commit/a0c61ca) Fix git option migration bug
- [`22419cb`](https://github.com/phil294/git-log--graph/commit/22419cb) Make date/author-date/topo order a default option in git log
- [`2593ecc`](https://github.com/phil294/git-log--graph/commit/2593ecc) Change magic word in log action from `VSCode` and `stash_refs` to `{EXT_FORMAT}` and `{STASH_REFS}`. You will need to reset and save your git log configuration if you have changed it.
- [`03d5978`](https://github.com/phil294/git-log--graph/commit/03d5978) Git input: auto focus first param input

### 0.0.5 2023-01-16
- [`9a2c177`](https://github.com/phil294/git-log--graph/commit/9a2c177) Use vscode-codicons instead of unicode icons (#3)
- [`9ca9296`](https://github.com/phil294/git-log--graph/commit/9ca9296) Add default push and pull actions
- [`cbbd17c`](https://github.com/phil294/git-log--graph/commit/cbbd17c) Add `git rebase --abort` to the abort action
- [`9a821df`](https://github.com/phil294/git-log--graph/commit/9a821df) Fix git reset args


### 0.0.4 2022-10-12
- [`1496dac`](https://github.com/phil294/git-log--graph/commit/1496dac) Many style improvements
- [`1496dac`](https://github.com/phil294/git-log--graph/commit/1496dac) Filter now includes branch name of commit

### 0.0.3 2022-09-17
- [`8f9dfd4`](https://github.com/phil294/git-log--graph/commit/8f9dfd4) Add drag/drop for branches. These actions are also configurable. By default there's `merge` and `rebase`.
- [`90531ce`](https://github.com/phil294/git-log--graph/commit/90531ce) Highlight the HEAD branch all the time
- [`59b478d`](https://github.com/phil294/git-log--graph/commit/59b478d) When scrolling to branch tip, also select the respective commit
- [`8434cc4`](https://github.com/phil294/git-log--graph/commit/8434cc4) In stash commits, show untracked change files too
- [`836debd`](https://github.com/phil294/git-log--graph/commit/836debd) Add `git reset --merge` to the abort default action
- [`8c55bc2`](https://github.com/phil294/git-log--graph/commit/8c55bc2) Enforce/overwrite dark theme on everything. Native dark/light theme support would be better, but the easiest way forward to fix any remaining color issues.
- [`32e211a`](https://github.com/phil294/git-log--graph/commit/32e211a) Make git conflict message detection locale independent (hopefully)
- [`667fa11`](https://github.com/phil294/git-log--graph/commit/667fa11) Make the " (HEAD)" part clickable
- [`c861a8b`](https://github.com/phil294/git-log--graph/commit/c861a8b) Add a thin line below the nav bar in main view
- [`25a54bf`](https://github.com/phil294/git-log--graph/commit/25a54bf) Action configuration: Apply replacements to title and description also

### 0.0.2 2022-06-05
- [`ac6ceee`](https://github.com/phil294/git-log--graph/commit/ac6ceee) Set icon

### 0.0.1 2022-06-05