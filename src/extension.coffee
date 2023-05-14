vscode = require 'vscode'
{ join, dirname } = require('path')
util = require('util')
{ glob } = require('glob')
exec = util.promisify(require('child_process').exec)

``###* @typedef {{ type: 'response' | 'request' | 'push', command?: string, data?: any, error?: any, id: number | string }} BridgeMessage ###

EXT_NAME = 'git log --graph'
EXT_ID = 'git-log--graph'
START_CMD = 'git-log--graph.start'

selected_folder_path = ''
``###* @type {{name:string,path:string}[]} ###
folders = []
refresh_folders = =>
	folders = await Promise.all((vscode.workspace.workspaceFolders or []).map (root) =>
		paths = try await glob '**/.git',
			ignore: 'node_modules/**' # TODO maybe use some kind of vscode setting for this
			maxDepth: 3
			cwd: root.uri.fsPath
			signal: AbortSignal.timeout(2000)
		(paths or []).map (path) =>
			path = dirname(path)
			if path == '.' then path = ''
			name: if path then "#{root.name}/#{path}" else root.name
			path: join(root.uri.fsPath, path)
	).then (x) => x.flat()

``###* @type {vscode.FileSystemWatcher | null} ###
index_watcher = null
restart_index_watcher = =>
	if index_watcher
		index_watcher.dispose()
		index_watcher = null
	return if not selected_folder_path
	index_watcher = vscode.workspace.createFileSystemWatcher "#{selected_folder_path}/.git/index"
	index_change = =>
		return if Date.now() - last_git_execution < 1500
		console.info 'file watcher: git INDEX change' # from external, e.g. cli
		post_message
			type: 'push'
			id: 'git-index-change'
	index_watcher.onDidChange index_change
	index_watcher.onDidCreate index_change
	index_watcher.onDidDelete index_change

last_git_execution = 0
git = (###* @type string ### args) =>
	{ stdout, stderr } = await exec 'git ' + args,
		cwd: vscode.workspace.getConfiguration(EXT_ID).get('folder') or selected_folder_path
		# 35 MB. For scale, Linux kernel git graph (1 mio commits) in extension format is 538 MB or 7.4 MB for the first 15k commits
		maxBuffer: 1024 * 1024 * 35
	last_git_execution = Date.now()
	stdout

``###* @type {vscode.WebviewPanel | null} ###
panel = null

post_message = (###* @type BridgeMessage ### msg) =>
	panel?.webview.postMessage msg

module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	context.subscriptions.push vscode.workspace.registerTextDocumentContentProvider "#{EXT_ID}-git-show",
		provideTextDocumentContent: (uri) ->
			(try await git "show \"#{uri.path}\"") or ''

	context.subscriptions.push vscode.commands.registerCommand START_CMD, =>
		if panel
			panel.reveal()
			return

		panel = vscode.window.createWebviewPanel(EXT_NAME, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { enableScripts: true, retainContextWhenHidden: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist') ] })
		panel.iconPath = vscode.Uri.joinPath(context.extensionUri, "logo.png")
		view = panel.webview
		panel.onDidDispose =>
			panel = null

		await refresh_folders()
		selected_folder_path = context.workspaceState.get('selected_folder_path') or ''
		if not folders.some (folder) => folder.path == selected_folder_path
			selected_folder_path = folders[0]?.path or ''
		restart_index_watcher()

		view.onDidReceiveMessage (###* @type BridgeMessage ### message) =>
			d = message.data
			h = (###* @type {() => any} ### func) =>
				``###* @type BridgeMessage ###
				resp =
					type: 'response'
					id: message.id
				try
					resp.data = await func()
				catch e
					resp.error = e
				post_message resp
			switch message.type
				when 'request'
					switch message.command
						when 'git' then h =>
							git d
						when 'show-error-message' then h =>
							vscode.window.showErrorMessage d
						when 'show-information-message' then h =>
							vscode.window.showInformationMessage d
						when 'get-global-state' then h =>
							context.globalState.get d
						when 'set-global-state' then h =>
							context.globalState.update d.key, d.value
						when 'get-workspace-state' then h =>
							context.workspaceState.get d
						when 'set-workspace-state' then h =>
							context.workspaceState.update d.key, d.value
						when 'open-diff' then h =>
							uri_1 = vscode.Uri.parse "#{EXT_ID}-git-show:#{d.hashes[0]}:#{d.filename}"
							uri_2 = vscode.Uri.parse "#{EXT_ID}-git-show:#{d.hashes[1]}:#{d.filename}"
							vscode.commands.executeCommand 'vscode.diff', uri_1, uri_2, "#{d.filename} #{d.hashes[0]} vs. #{d.hashes[1]}"
						when 'get-config' then h =>
							vscode.workspace.getConfiguration(EXT_ID).get d
						when 'get-folder-names' then h =>
							folders.map (f) => f.name
						when 'set-selected-folder-index' then h =>
							selected_folder_path = folders[Number(d)]?.path or ''
							context.workspaceState.update 'selected_folder_path', selected_folder_path
							restart_index_watcher()
						when 'get-selected-folder-index' then h =>
							folders.findIndex (folder) =>
								folder.path == selected_folder_path
		vscode.workspace.onDidChangeConfiguration (event) =>
			if event.affectsConfiguration EXT_ID
				post_message
					type: 'push'
					id: 'config-change'

		is_production = context.extensionMode == vscode.ExtensionMode.Production
		dev_server_url = 'http://localhost:8080'
		csp = "default-src 'none'; " +
			"style-src #{view.cspSource} 'unsafe-inline' " +
				(if is_production then '' else dev_server_url) + '; ' +
			"script-src #{view.cspSource} 'unsafe-inline' " +
				(if is_production then '' else "#{dev_server_url} 'unsafe-eval'") + '; ' +
			"font-src #{view.cspSource} " +
				(if is_production then '' else dev_server_url) + '; ' +
			"connect-src " +
				(if is_production then '' else '*') + '; '
		get_web_uri = (###* @type {string[]} ### ...path_segments) =>
			if is_production
				view.asWebviewUri vscode.Uri.joinPath context.extensionUri, 'web-dist', ...path_segments
			else
				[dev_server_url, ...path_segments].join('/')
		view.html = "
			<!DOCTYPE html>
			<html lang='en'>
			<head>
				<meta charset='UTF-8'>
				<meta http-equiv='Content-Security-Policy' content=\"#{csp}\">
				<meta name='viewport' content='width=device-width, initial-scale=1.0'>
				<link href='#{get_web_uri 'css', 'app.css'}' rel='stylesheet'>
				<style>
					@font-face {
						font-family: 'codicon';
						src: url('#{get_web_uri 'fonts', 'codicon.ttf'}') format('truetype');
					}
				</style>
				<title>#{EXT_NAME}</title>
			</head>
			<body>
				<div id='app'></div>
				<script src='#{get_web_uri 'js', 'chunk-vendors.js'}'></script>
				<script src='#{get_web_uri 'js', 'app.js'}'></script>
			</body>
			</html>"

	status_bar_item = vscode.window.createStatusBarItem vscode.StatusBarAlignment.Left
	status_bar_item.command = START_CMD
	context.subscriptions.push status_bar_item
	status_bar_item.text = "$(git-branch) Git Log"
	status_bar_item.tooltip = "Open up the main view of the git-log--graph extension"
	status_bar_item.show()