let vscode = require('vscode')
let util = require('util')
let { basename, relative, isAbsolute } = require('path')
const { existsSync } = require('fs')
let { realpath } = require('fs').promises
let exec = util.promisify(require('child_process').exec)

/**
 * @param EXT_ID {string}
 * @param logger {ReturnType<import('./logger')>}
 * @param args {{on_repo_external_state_change:()=>any, on_repo_names_change:()=>any}}
 */
module.exports.get_git = function(EXT_ID, logger, { on_repo_external_state_change, on_repo_names_change }) {
	/** @type {import('./vscode.git').API} */
	let api = vscode.extensions.getExtension('vscode.git')?.exports.getAPI(1) || (() => { throw 'VSCode official Git Extension not found, did you disable it?' })()
	let last_git_execution = 0

	/** @type {Record<string,string>} */
	let repo_state_cache = {}
	function start_observing_repo(/** @type {import('./vscode.git').Repository} */ repo) {
		logger.info('start observing repo ' + repo.rootUri.fsPath)
		return repo.state.onDidChange(() => {
			// There's no event info available so we need to compare. (https://github.com/microsoft/vscode/issues/142313#issuecomment-1056939973)
			// Work tree changes is required for detecting stashes.
			// Detecting branch additions is currently *not possible*.
			let state_cache = [repo.state.mergeChanges.map((c) => c.uri.fsPath).join(','), repo.state.HEAD?.commit, repo.state.workingTreeChanges.map((c) => c.uri.fsPath).join(','), repo.state.indexChanges.map((c) => c.uri.fsPath).join(',')].join(';')
			let is_initial_change = ! repo_state_cache[repo.rootUri.fsPath]
			if (repo_state_cache[repo.rootUri.fsPath] === state_cache)
				return
			repo_state_cache[repo.rootUri.fsPath] = state_cache
			if (is_initial_change)
				return
			// Changes done via interface already do a refresh afterwards, so prevent a second one.
			// Another solution does not really seem feasible, as it's hard to tell when a change
			// was made by the user. Some commands never do (log, branch --list, ...), others only
			// sometimes, depending on work tree and command success. So it would be necessary to
			// have a separate change detection logic based on .git/HEAD and .git/index because
			// this one right here is too delayed. vscode.git keeps its own state and refreshes quite
			// slowly but we need immediate refreshes in the interface while *not* doing duplicate
			// refreshes for the same action. It seems the sanest solution is just a dumb timer.
			// The delay margin should be as big as possible in case the repo is *very* big and
			// a false positive resulting from a a too small margin can lead to *seconds* of
			// unnecessary reloading, and it should be as small as possible to prevent actual external
			// changes from being detected which could happen if the user e.g. checks out a branch in
			// the extension's interface and then quickly commits something from VSCode's SCM view
			// before the margin elapsed.
			// Note that `last_git_execution` would usually refer to a `git log` action because any
			// git action in the web view results in a refresh / log being sent afterwards.
			let margin = 1500
			if (Date.now() - last_git_execution < margin)
				return
			// We have to observe all repos even if they aren't the selected one because
			// there is no apparent way to unsubscribe from repo state changes. So filter:
			if (api.repositories.findIndex((r) => r.rootUri.path === repo.rootUri.path) !== selected_repo_index)
				return
			logger.info('repo watcher: external index/head change') // from external, e.g. cli or committed via vscode ui
			return on_repo_external_state_change()
		})
	}

	/** @type {import('./vscode.git').Repository[]} */
	let repos_cache = []
	function repos_changed() {
		// onDidOpenRepository fires multiple times. At first, there isn't even a repos change..
		if (api.repositories.length === repos_cache.length)
			return
		debounce(() => {
			logger.info('workspace: repo(s) added/removed')
			api.repositories.filter((repo) => ! repos_cache.includes(repo)).forEach((repo) =>
				start_observing_repo(repo))
			repos_cache = api.repositories.slice()
			return on_repo_names_change()
		}, 200)
	}
	api.onDidOpenRepository(repos_changed)
	api.onDidCloseRepository(repos_changed)
	api.onDidChangeState(repos_changed)
	repos_changed()

	let selected_repo_index = 0
	return {
		/** Guaranteed to be unique, but if possible, just the folder name */
		get_repo_names() {
			return Object.entries(api.repositories.reduce((/** @type {Record<string, Array<import('./vscode.git').Repository>>} */ all, repo) => {
				let base = basename(repo.rootUri.path)
				all[base] ||= []
				all[base].push(repo)
				return all
			}, {}))
				.map(([base, repos]) =>
					repos.length === 1
						? base : repos.map(repo =>
							repo.rootUri.path))
				.flat()
		},
		get_repo(/** @type {number|undefined} */ repo_index) {
			if (repo_index == null)
				repo_index = selected_repo_index
			let repo = api.repositories.at(repo_index)
			if (! repo && repo_index > 0)
				repo = api.repositories.at(0)
			return repo
		},
		async run(/** @type {string} */ args, /** @type {number|undefined} */ repo_index) {
			let cwd = vscode.workspace.getConfiguration(EXT_ID).get('folder')
			let cmd = vscode.workspace.getConfiguration(EXT_ID).get('git-path') ||
				vscode.workspace.getConfiguration('git').get('path') || 'git'
			if (! cwd) {
				let repo = this.get_repo(repo_index)
				if (! repo)
					throw 'No repository selected'
				cwd = repo.rootUri.fsPath
			}
			try {
				let { stdout } = await exec(cmd + ' ' + args, {
					cwd,
					// 35 MB. For scale, Linux kernel git graph (1 mio commits) in extension format
					// is 538 MB or 7.4 MB for the first 15k commits
					maxBuffer: 1024 * 1024 * 35,
				})
				last_git_execution = Date.now()
				return stdout
			} catch (error) {
				// stderr contains the full message, message itself is too short otherwise
				// In the case of multi-step commands like branch drop merge, stdout instead
				// contains the actual important message.
				// When the error comes from the internals of cp/exec, it's in .message.
				error.message = [error.stderr, error.stdout].join('\n').trim() || error.message || error.code
				throw error
			}
		},
		set_selected_repo_index(/** @type {number} */ index) {
			logger.info('set selected repo index ' + index)
			selected_repo_index = index
		},
		get_selected_repo_index: () => selected_repo_index,
		async get_repo_index_for_uri(/** @type {vscode.Uri} */ uri) {
			if (! existsSync(uri.fsPath))
				return -1
			let uri_path = await realpath(uri.fsPath).catch(e => { throw new Error(e) /* https://github.com/nodejs/node/issues/30944 */ })
			return ((await Promise.all(api.repositories.map(async (repo, index) => {
				let repo_path = await realpath(repo.rootUri.fsPath).catch(e => { throw new Error(e) /* https://github.com/nodejs/node/issues/30944 */ })
				return { repo_path, index }
			})))).filter(({ repo_path }) => {
				// if repo includes uri: stackoverflow.com/q/37521893
				let rel = relative(repo_path, uri_path)
				return rel != null && ! rel.startsWith('..') && ! isAbsolute(rel)
				// There can be multiple matches with git submodules, in which case the longest
				// path will be the right one
			}).sort((a, b) =>
				b.repo_path.length - a.repo_path.length)
				.at(0)?.index ?? -1
		},
	}
}
