vscode = require 'vscode'
{ join, dirname } = require('path')
util = require('util')
{ glob } = require('glob')
exec = util.promisify(require('child_process').exec)

``###* @typedef {{ type: 'response' | 'request' | 'push', command?: string, data?: any, error?: any, id: number | string }} BridgeMessage ###

EXT_NAME = 'git log --graph'
EXT_ID = 'git-log--graph'

selected_folder_path = ''
``###* @type {{name:string,path:string}[]} ###
folders = []
refresh_folders = =>
	folders = await Promise.all((vscode.workspace.workspaceFolders or []).map (root) =>
		paths = await glob '**/.git',
			ignore: 'node_modules/**' # TODO maybe use some kind of vscode setting for this
			maxDepth: 3
			cwd: root.uri.fsPath
			signal: AbortSignal.timeout(200)
		paths.map (path) =>
			path = dirname(path)
			if path == '.' then path = ''
			name: if path then "#{root.name}/#{path}" else root.name
			path: join(root.uri.fsPath, path)
	).then (x) => x.flat()

git = (###* @type string ### args) =>
	{ stdout, stderr } = await exec 'git ' + args,
		cwd: vscode.workspace.getConfiguration(EXT_ID).get('folder') or selected_folder_path
		# 35 MB. For scale, Linux kernel git graph (1 mio commits) in extension format is 538 MB or 7.4 MB for the first 15k commits
		maxBuffer: 1024 * 1024 * 35
	stdout

module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	context.subscriptions.push vscode.workspace.registerTextDocumentContentProvider 'git-show',
		provideTextDocumentContent: (uri) ->
			(try await git "show \"#{uri.path}\"") or ''

	context.subscriptions.push vscode.commands.registerCommand 'git-log--graph.start', =>
		panel = vscode.window.createWebviewPanel(EXT_NAME, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { enableScripts: true, retainContextWhenHidden: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist') ] })
		panel.iconPath = vscode.Uri.joinPath(context.extensionUri, "logo.png")
		view = panel.webview

		await refresh_folders()
		selected_folder_path = context.workspaceState.get('selected_folder_path') or ''
		if not folders.some (folder) => folder.path == selected_folder_path
			selected_folder_path = folders[0]?.path or ''

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
				view.postMessage resp
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
							uri_1 = vscode.Uri.parse "git-show:#{d.hash}~1:#{d.filename}"
							uri_2 = vscode.Uri.parse "git-show:#{d.hash}:#{d.filename}"
							vscode.commands.executeCommand 'vscode.diff', uri_1, uri_2, "#{d.filename} @#{d.hash}"
						when 'get-config' then h =>
							vscode.workspace.getConfiguration(EXT_ID).get d
						when 'get-folder-names' then h =>
							folders.map (f) => f.name
						when 'set-selected-folder-index' then h =>
							selected_folder_path = folders[Number(d)]?.path or ''
							context.workspaceState.update 'selected_folder_path', selected_folder_path
						when 'get-selected-folder-index' then h =>
							folders.findIndex (folder) =>
								folder.path == selected_folder_path
		vscode.workspace.onDidChangeConfiguration (event) =>
			if event.affectsConfiguration EXT_ID
				``###* @type BridgeMessage ###
				msg =
					type: 'push'
					id: 'config-change'
				view.postMessage msg

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