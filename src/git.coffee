vscode = require 'vscode'
util = require('util')
{ basename } = require('path')
exec = util.promisify(require('child_process').exec)

``###*
# @param EXT_ID {string}
# @param log {vscode.OutputChannel}
# @param args {{on_repo_external_state_change:()=>any, on_repo_names_change:()=>any}}
###
module.exports.get_git = (EXT_ID, log, { on_repo_external_state_change, on_repo_names_change }) =>
	#
	###* @type {import('./vscode.git').API} ###
	api = vscode.extensions.getExtension('vscode.git')?.exports.getAPI(1) or throw 'VSCode official Git Extension not found, did you disable it?'
	last_git_execution = 0

	``###* @type {Record<string,string>} ###
	repo_state_cache = {}
	start_observing_repo = (###* @type {import('./vscode.git').Repository} ### repo) =>
		log.appendLine "start observing repo "+repo.rootUri.fsPath
		repo.state.onDidChange =>
			# There's no event info available so we need to compare. (https://github.com/microsoft/vscode/issues/142313#issuecomment-1056939973)
			# Skipping index/work tree changes just in case the repository is very big,
			# this could lead to unnecessary loading times as we don't really show index/worktree
			# changes except the little grey status text at the start and this is acceptable
			# given we're talking about external changes only.
			# repo.state.workingTreeChanges.map((c)=>c.uri.fsPath).join(','), repo.state.indexChanges.map((c)=>c.uri.fsPath).join(',')
			state_cache = [repo.state.mergeChanges.map((c)=>c.uri.fsPath).join(','), repo.state.HEAD?.commit].join(';')
			is_initial_change = not repo_state_cache[repo.rootUri.fsPath]
			return if repo_state_cache[repo.rootUri.fsPath] == state_cache
			repo_state_cache[repo.rootUri.fsPath] = state_cache
			return if is_initial_change
			# Changes done via interface already do a refresh afterwards, so prevent a second one.
			# Another solution does not really seem feasible, as it's hard to tell when a change
			# was made by the user. Some commands never do (log, branch --list, ...), others only
			# sometimes, depending on work tree and command success. So it would be necessary to
			# have a separate change detection logic based on .git/HEAD and .git/index because
			# this one right here is too delayed. vscode.git keeps its own state and refreshes quite
			# slowly but we need immediate refreshes in the interface while *not* doing duplicate
			# refreshes for the same action. It seems the sanest solution is just a dumb timer.
			# The delay margin should be as big as possible in case the repo is *very* big and
			# a false positive resulting from a a too small margin can lead to *seconds* of
			# unnecessary reloading, and it should be as small as possible to prevent actual external
			# changes from being detected which could happen if the user e.g. checks out a branch in
			# the extension's interface and then quickly commits something from VSCode's SCM view
			# before the margin elapsed.
			# Note that `last_git_execution` would usually refer to a `git log` action because any
			# git action in the web view results in a refresh / log being sent afterwards.
			margin = 1500
			return if Date.now() - last_git_execution < margin
			# We have to observe all repos even if they aren't the selected one because
			# there is no apparent way to unsubscribe from repo state changes. So filter:
			return if api.repositories.findIndex((r)=>r.rootUri.path==repo.rootUri.path) != selected_repo_index
			log.appendLine 'repo watcher: external index/head change' # from external, e.g. cli or committed via vscode ui
			on_repo_external_state_change()

	``###* @type {import('./vscode.git').Repository[]} ###
	repos_cache = []
	``###* @type {NodeJS.Timeout|null} ###
	repos_changed_debouncer = null
	repos_changed = =>
		# onDidOpenRepository fires multiple times. At first, there isn't even a repos change..
		return if api.repositories.length == repos_cache.length
		clearTimeout repos_changed_debouncer if repos_changed_debouncer
		repos_changed_debouncer = setTimeout (=>
			log.appendLine 'workspace: repo(s) added/removed'
			api.repositories
				.filter (repo) => not repos_cache.includes(repo)
				.forEach (repo) =>
					start_observing_repo repo
			repos_cache = api.repositories.slice()
			on_repo_names_change()
		), 200
	api.onDidOpenRepository repos_changed
	api.onDidCloseRepository repos_changed
	api.onDidChangeState repos_changed
	do repos_changed

	selected_repo_index = 0
	{
		get_repo_names: =>
			api.repositories.map (f) => basename f.rootUri.path
		run: (###* @type string ### args) =>
			cwd = vscode.workspace.getConfiguration(EXT_ID).get('folder')
			if not cwd
				repo = api.repositories[selected_repo_index]
				throw 'No repository found/selected' if not repo
				cwd = repo.rootUri.fsPath
			{ stdout, stderr: _ } = await exec 'git ' + args,
				cwd: cwd
				# 35 MB. For scale, Linux kernel git graph (1 mio commits) in extension format
				# is 538 MB or 7.4 MB for the first 15k commits
				maxBuffer: 1024 * 1024 * 35
			last_git_execution = Date.now()
			stdout
		set_selected_repo_index: (###* @type number ### index) =>
			log.appendLine "set selected repo index "+index
			selected_repo_index = index
		get_selected_repo_index: => selected_repo_index
	}
