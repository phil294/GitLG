vscode = require 'vscode'

{ get_git } = require './git'

``###* @typedef {{ type: 'response' | 'request' | 'push', command?: string, data?: any, error?: any, id: number | string }} BridgeMessage ###

EXT_NAME = 'git log --graph'
EXT_ID = 'git-log--graph'
START_CMD = 'git-log--graph.start'

``###* @type {vscode.WebviewPanel | null} ###
panel = null

log = vscode.window.createOutputChannel EXT_NAME
module.exports.log = log

# When you convert a folder into a workspace by adding another folder, the extension is de- and reactivated
# but the webview panel isn't destroyed even though we instruct it to (with subscriptions).
# This is an unresolved bug in VSCode and it seems there is nothing you can do. https://github.com/microsoft/vscode/issues/158839
module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	log.appendLine "extension activate"

	post_message = (###* @type BridgeMessage ### msg) =>
		log.appendLine "send to webview: "+JSON.stringify(msg) if vscode.workspace.getConfiguration(EXT_ID).get('verbose-logging')
		panel?.webview.postMessage msg

	git = get_git log,
		on_repo_external_state_change: =>
			post_message
				type: 'push'
				id: 'repo-external-state-change'
		on_repo_names_change: =>
			post_message
				type: 'push'
				id: 'repo-names-change'
				data: git.get_repo_names()

	populate_panel = =>
		return if not panel
		view = panel.webview
		view.options = { enableScripts: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist') ] }
		panel.onDidDispose => panel = null
		context.subscriptions.push panel

		git.set_selected_repo_index(context.workspaceState.get('selected_repo_index') or 0)

		view.onDidReceiveMessage (###* @type BridgeMessage ### message) =>
			log.appendLine "receive from webview: "+JSON.stringify(message)  if vscode.workspace.getConfiguration(EXT_ID).get('verbose-logging')
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
							git.run d
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
						when 'get-repo-names' then h =>
							git.get_repo_names()
						when 'set-selected-repo-index' then h =>
							index = Number(d) or 0
							context.workspaceState.update 'selected_repo_index', index
							git.set_selected_repo_index(index)
						when 'get-selected-repo-index' then h =>
							git.get_selected_repo_index()
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
	
	context.subscriptions.push vscode.workspace.registerTextDocumentContentProvider "#{EXT_ID}-git-show",
		provideTextDocumentContent: (uri) ->
			(try await git.run "show \"#{uri.path}\"") or ''

	context.subscriptions.push vscode.commands.registerCommand START_CMD, =>
		log.appendLine "start command"
		return panel.reveal() if panel
		panel = vscode.window.createWebviewPanel(EXT_ID, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { retainContextWhenHidden: true })
		panel.iconPath = vscode.Uri.joinPath(context.extensionUri, "logo.png")
		populate_panel()

	# This bit is needed so the webview can keep open around restarts
	vscode.window.registerWebviewPanelSerializer EXT_ID,
		deserializeWebviewPanel: (deserialized_panel) ->
			panel = deserialized_panel
			log.appendLine "deserialize web panel (rebuild editor tab from last session)"
			await populate_panel()
			undefined

	status_bar_item = vscode.window.createStatusBarItem vscode.StatusBarAlignment.Left
	status_bar_item.command = START_CMD
	context.subscriptions.push status_bar_item
	status_bar_item.text = "$(git-branch) Git Log"
	status_bar_item.tooltip = "Open up the main view of the git-log--graph extension"
	status_bar_item.show()

module.exports.deactivate = =>
	log.appendLine("extension deactivate")