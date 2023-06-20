vscode = require 'vscode'
path = require 'path'
postcss = require 'postcss'
postcss_sanitize = require 'postcss-sanitize'

{ get_git } = require './git'

``###* @typedef {{ type: 'response' | 'request' | 'push', command?: string, data?: any, error?: any, id: number | string }} BridgeMessage ###

EXT_NAME = 'git log --graph'
EXT_ID = 'git-log--graph'
START_CMD = 'git-log--graph.start'

``###* @type {vscode.WebviewPanel | vscode.WebviewView | null} ###
webview_container = null

# todo proper log with timestamps like e.g. git or extension host
log = vscode.window.createOutputChannel EXT_NAME
module.exports.log = log
log_error = (###* @type string ### e) =>
	vscode.window.showErrorMessage 'git-log--graph: '+e
	log.appendLine "ERROR: #{e}"

# When you convert a folder into a workspace by adding another folder, the extension is de- and reactivated
# but the webview webview_container isn't destroyed even though we instruct it to (with subscriptions).
# This is an unresolved bug in VSCode and it seems there is nothing you can do. https://github.com/microsoft/vscode/issues/158839
module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	log.appendLine "extension activate"

	post_message = (###* @type BridgeMessage ### msg) =>
		log.appendLine "send to webview: "+JSON.stringify(msg) if vscode.workspace.getConfiguration(EXT_ID).get('verbose-logging')
		webview_container?.webview.postMessage msg
	push_message_id = (###* @type {string} ### id) =>
		post_message
			type: 'push'
			id: id

	git = get_git EXT_ID, log,
		on_repo_external_state_change: =>
			push_message_id 'repo-external-state-change'
		on_repo_names_change: =>
			state('repo-names').set(git.get_repo_names())

	state = do =>
		global_state_memento = (###* @type string ### key) =>
			get: => context.globalState.get(key)
			set: (###* @type any ### v) => context.globalState.update(key, v)
		# workspace_state_memento = (###* @type string ### key) =>
		# 	get: => context.workspaceState.get(key)
		# 	set: (###* @type any ### v) => context.workspaceState.update(key, v)
		``###* @type {Record<string, {get:()=>any,set:(value:any)=>any}>} ###
		kv =
			'selected-repo-index':
				get: => context.workspaceState.get('selected-repo-index')
				set: (v) =>
					context.workspaceState.update('selected-repo-index', v)
					git.set_selected_repo_index(Number(v) or 0)
			'repo-names':
				get: => git.get_repo_names()
				set: =>
			# 'abc': global_state_memento('def')
		default_memento = global_state_memento
		(###* @type string ### key) =>
			memento = kv[key] or default_memento(key)
			get: memento.get
			set: (###* @type any ### value, ###* @type {{broadcast?:boolean}} ### options = {}) =>
				memento.set(value)
				if options.broadcast != false
					post_message
						type: 'push'
						id: 'state-update'
						data: { key, value }
				undefined

	populate_webview = =>
		return if not webview_container
		view = webview_container.webview
		view.options = { enableScripts: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist') ] }

		view.onDidReceiveMessage (###* @type BridgeMessage ### message) =>
			log.appendLine "receive from webview: "+JSON.stringify(message) if vscode.workspace.getConfiguration(EXT_ID).get('verbose-logging')
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
							log_error d
						when 'show-information-message' then h =>
							vscode.window.showInformationMessage d
						when 'get-config' then h =>
							vscode.workspace.getConfiguration(EXT_ID)
						when 'get-state' then h =>
							state(d).get()
						when 'set-state' then h =>
							state(d.key).set(d.value, broadcast: false)
						when 'open-diff' then h =>
							uri_1 = vscode.Uri.parse "#{EXT_ID}-git-show:#{d.hashes[0]}:#{d.filename}"
							uri_2 = vscode.Uri.parse "#{EXT_ID}-git-show:#{d.hashes[1]}:#{d.filename}"
							vscode.commands.executeCommand 'vscode.diff', uri_1, uri_2, "#{d.filename} #{d.hashes[0]} vs. #{d.hashes[1]}"
						when 'view-rev' then h =>
							uri = vscode.Uri.parse "#{EXT_ID}-git-show:#{d.hash}:#{d.filename}"
							vscode.commands.executeCommand 'vscode.open', uri
						when 'open-file' then h =>
							workspace = vscode.workspace.workspaceFolders[git.get_selected_repo_index()].uri.fsPath
							uri = vscode.Uri.file path.join workspace, d.filename
							vscode.commands.executeCommand 'vscode.open', uri

		``###* @type {NodeJS.Timeout|null} ###
		config_change_debouncer = null
		vscode.workspace.onDidChangeConfiguration (event) =>
			if event.affectsConfiguration EXT_ID
				clearTimeout config_change_debouncer if config_change_debouncer
				config_change_debouncer = setTimeout (=>
					push_message_id 'config-change'
				), 500

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
				(if is_production then '' else '*') + '; ' +
			"img-src #{view.cspSource} " +
				(if is_production then '' else dev_server_url) + '; '
		get_web_uri = (###* @type {string[]} ### ...path_segments) =>
			if is_production
				view.asWebviewUri vscode.Uri.joinPath context.extensionUri, 'web-dist', ...path_segments
			else
				[dev_server_url, ...path_segments].join('/')
		custom_css = vscode.workspace.getConfiguration(EXT_ID).get('custom-css') or '{body:text-transform uppercase;}'
		if custom_css
			custom_css = try (await postcss([postcss_sanitize({})]).process(custom_css, { from: undefined })).css

		view.html = "
			<!DOCTYPE html>
			<html lang='en'>
			<head>
				<meta charset='UTF-8'>
				<meta http-equiv='Content-Security-Policy' content=\"#{csp}\">
				<meta name='viewport' content='width=device-width, initial-scale=1.0'>
				<link href='#{get_web_uri 'css', 'app.css'}' rel='stylesheet'>
				<title>#{EXT_NAME}</title>
			</head>
			<body>
				<div id='app'></div>
				<script src='#{get_web_uri 'js', 'chunk-vendors.js'}'></script>
				<script src='#{get_web_uri 'js', 'app.js'}'></script>
				<style>#{custom_css}</style>
			</body>
			</html>"
		undefined

	# Needed for git diff views
	context.subscriptions.push vscode.workspace.registerTextDocumentContentProvider "#{EXT_ID}-git-show",
		provideTextDocumentContent: (uri) ->
			(try await git.run "show \"#{uri.path}\"") or ''

	# General start, will choose from creating/show editor panel or showing side nav view depending on config
	context.subscriptions.push vscode.commands.registerCommand START_CMD, =>
		log.appendLine "start command"
		if vscode.workspace.getConfiguration(EXT_ID).get('position') == "editor"
			if webview_container
				# Repeated editor panel show
				# @ts-ignore
				return webview_container.reveal()
			# First editor panel creation + show
			log.appendLine "create new webview panel"
			webview_container = vscode.window.createWebviewPanel(EXT_ID, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { retainContextWhenHidden: true })
			webview_container.iconPath = vscode.Uri.joinPath(context.extensionUri, "logo.png")
			webview_container.onDidDispose => webview_container = null
			context.subscriptions.push webview_container
			populate_webview()
		else
			# Repeated side nav view show
			log.appendLine "show view"
			# @ts-ignore
			webview_container?.show()

	# First editor panel creation + show, but automatically after restart / resume previous session.
	# It would be possible to restore some web view state here too
	vscode.window.registerWebviewPanelSerializer EXT_ID,
		deserializeWebviewPanel: (deserialized_panel) ->
			log.appendLine "deserialize web panel (rebuild editor tab from last session)"
			webview_container = deserialized_panel
			webview_container.onDidDispose => webview_container = null
			context.subscriptions.push webview_container
			populate_webview()
			Promise.resolve()

	# Side nav view setup
	context.subscriptions.push vscode.window.registerWebviewViewProvider EXT_ID, {
		# Side nav view creation
		resolveWebviewView: (view) =>
			return if vscode.workspace.getConfiguration(EXT_ID).get('position') == "editor"
			log.appendLine "provide view"
			webview_container = view
			populate_webview()
		}, { webviewOptions: retainContextWhenHidden: true }

	status_bar_item = vscode.window.createStatusBarItem vscode.StatusBarAlignment.Left
	status_bar_item.command = START_CMD
	context.subscriptions.push status_bar_item
	status_bar_item.text = "$(git-branch) Git Log"
	status_bar_item.tooltip = "Open up the main view of the git-log--graph extension"
	status_bar_item.show()

	# public api of this extension:
	{ git, post_message, webview_container, context, state }

module.exports.deactivate = =>
	log.appendLine("extension deactivate")