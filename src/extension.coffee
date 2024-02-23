vscode = require 'vscode'
path = require 'path'
postcss = require 'postcss'
postcss_sanitize = require 'postcss-sanitize'
RelativeTime = require '@yaireo/relative-time'
relative_time = new RelativeTime

{ get_git } = require './git'

###* @typedef {{ type: 'response' | 'request' | 'push', command?: string, data?: any, error?: any, id: number | string }} BridgeMessage ###

EXT_NAME = 'git log --graph'
EXT_ID = 'git-log--graph'
START_CMD = 'git-log--graph.start'
BLAME_CMD = 'git-log--graph.blame-line'

###* @type {vscode.WebviewPanel | vscode.WebviewView | null} ###
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

	# something to be synchronized with the web view - initialization, storage,
	# update and retrieval is supported in both directions
	state = do =>
		global_state_memento = (###* @type string ### key) =>
			get: => context.globalState.get(key)
			set: (###* @type any ### v) => context.globalState.update(key, v)
		workspace_state_memento = (###* @type string ### key) =>
			get: => context.workspaceState.get(key)
			set: (###* @type any ### v) => context.workspaceState.update(key, v)
		repo_state_memento = (###* @type string ### local_key) =>
			key = =>
				repo_name = git.get_repo_names()[state('selected-repo-index').get()]
				"repo-#{local_key}-#{repo_name}"
			get: => context.workspaceState.get(key())
			set: (###* @type any ### v) => context.workspaceState.update(key(), v)
		###* @type {Record<string, {get:()=>any,set:(value:any)=>any}>} ###
		special_states = # "Normal" states instead are just default_memento
			'selected-repo-index':
				get: => context.workspaceState.get('selected-repo-index')
				set: (v) =>
					context.workspaceState.update('selected-repo-index', v)
					git.set_selected_repo_index(Number(v) or 0)
					# These will have changed now, so notify clients of updated value
					for key from ['repo:action-history', 'repo:selected-commits-hashes']
						state(key).set(state(key).get())
			'repo-names':
				get: => git.get_repo_names()
				set: =>
			'repo:selected-commits-hashes': repo_state_memento('selected-commits-hashes')
			'repo:action-history': repo_state_memento('action-history')
		default_memento = global_state_memento
		(###* @type string ### key) =>
			memento = special_states[key] or default_memento(key)
			get: memento.get
			set: (###* @type any ### value, ###* @type {{broadcast?:boolean}} ### options = {}) =>
				memento.set(value)
				if options.broadcast != false
					post_message
						type: 'push'
						id: 'state-update'
						data: { key, value }
				undefined

	git.set_selected_repo_index(state('selected-repo-index').get() or 0)

	populate_webview = =>
		return if not webview_container
		view = webview_container.webview
		view.options = { enableScripts: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist') ] }

		view.onDidReceiveMessage (###* @type BridgeMessage ### message) =>
			log.appendLine "receive from webview: "+JSON.stringify(message) if vscode.workspace.getConfiguration(EXT_ID).get('verbose-logging')
			d = message.data
			h = (###* @type {() => any} ### func) =>
				###* @type BridgeMessage ###
				resp =
					type: 'response'
					id: message.id
				try
					resp.data = await func()
				catch e
					console.warn e
					# We can't really just be passing e along here because it might be serialized as empty {}
					resp.error = e.message || e
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

		###* @type {NodeJS.Timeout|null} ###
		config_change_debouncer = null
		vscode.workspace.onDidChangeConfiguration (event) =>
			if event.affectsConfiguration EXT_ID
				clearTimeout config_change_debouncer if config_change_debouncer
				config_change_debouncer = setTimeout (=>
					push_message_id 'config-change'
				), 500

		is_production = context.extensionMode == vscode.ExtensionMode.Production or process.env.GIT_LOG__GRAPH_MODE == 'production'
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
		custom_css = vscode.workspace.getConfiguration(EXT_ID).get('custom-css')
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
				<style>#{custom_css}</style>
			</body>
			</html>"
		undefined

	# Needed for git diff views
	context.subscriptions.push vscode.workspace.registerTextDocumentContentProvider "#{EXT_ID}-git-show",
		provideTextDocumentContent: (uri) ->
			(try await git.run "show \"#{uri.path}\"") or ''

	# General start, will choose from creating/show editor panel or showing side nav view depending on config
	context.subscriptions.push vscode.commands.registerCommand START_CMD, (args) =>
		log.appendLine "start command"
		if args?.rootUri # invoked via menu scm/title
			state('selected-repo-index').set(await git.get_repo_index_for_uri(args.rootUri))
		if vscode.workspace.getConfiguration(EXT_ID).get('position') == "editor"
			if webview_container
				# Repeated editor panel show
				# @ts-ignore
				return webview_container.reveal()
			# First editor panel creation + show
			log.appendLine "create new webview panel"
			webview_container = vscode.window.createWebviewPanel(EXT_ID, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { retainContextWhenHidden: true })
			webview_container.iconPath = vscode.Uri.joinPath(context.extensionUri, "img", "logo.png")
			webview_container.onDidDispose => webview_container = null
			context.subscriptions.push webview_container
			populate_webview()
		else
			# Repeated side nav view show
			log.appendLine "show view"
			# @ts-ignore
			webview_container?.show()

	# Close the editor(tab)
	context.subscriptions.push vscode.commands.registerCommand 'git-log--graph.close', =>
		if vscode.workspace.getConfiguration(EXT_ID).get('position') != "editor"
			return vscode.window.showInformationMessage "This command is can only be used if git-log--graph isn't configured as a main editor (tab)."
		if ! webview_container
			return vscode.window.showInformationMessage "git-log--graph editor tab is not running."
		log.appendLine "close command"
		# @ts-ignore
		webview_container.dispose()

	# Toggle the editor(tab)
	context.subscriptions.push vscode.commands.registerCommand 'git-log--graph.toggle', =>
		if vscode.workspace.getConfiguration(EXT_ID).get('position') != "editor"
			return vscode.window.showInformationMessage "This command is can only be used if git-log--graph isn't configured as a main editor (tab)."
		log.appendLine "toggle command"
		if webview_container
			# @ts-ignore
			return webview_container.dispose()
		vscode.commands.executeCommand(START_CMD)

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

	status_bar_item_command = vscode.window.createStatusBarItem vscode.StatusBarAlignment.Left
	status_bar_item_command.command = START_CMD
	context.subscriptions.push status_bar_item_command
	status_bar_item_command.text = "$(git-branch) Git Log"
	status_bar_item_command.tooltip = "Open up the main view of the git-log--graph extension"
	status_bar_item_command.show()

	status_bar_item_blame = vscode.window.createStatusBarItem vscode.StatusBarAlignment.Right, 500
	status_bar_item_blame.command = BLAME_CMD
	context.subscriptions.push status_bar_item_blame
	status_bar_item_blame.text = ""
	status_bar_item_blame.tooltip = "Show and focus this commit in the main view of the git-log--graph extension"
	status_bar_item_blame.show()

	current_line = -1
	current_line_repo_index = -1
	current_line_long_hash = ''
	###* @type {NodeJS.Timeout|null} ###
	line_change_debouncer = null
	hide_blame = =>
		clearTimeout line_change_debouncer if line_change_debouncer
		current_line_long_hash = ''
		status_bar_item_blame.text = ""
	vscode.workspace.onDidCloseTextDocument hide_blame
	vscode.window.onDidChangeActiveTextEditor hide_blame
	vscode.window.onDidChangeTextEditorSelection ({ textEditor: text_editor }) =>
		doc = text_editor.document
		uri = doc.uri
		return if uri.scheme != 'file' || doc.languageId == 'log' || doc.languageId == 'Log' || uri.path.includes('extension-output') || uri.path.includes(EXT_ID) # vscode/issues/206118
		return if text_editor.selection.active.line == current_line
		current_line = text_editor.selection.active.line
		clearTimeout line_change_debouncer if line_change_debouncer
		line_change_debouncer = setTimeout (=>
			current_line_repo_index = await git.get_repo_index_for_uri uri
			return hide_blame() if current_line_repo_index < 0
			blamed = try (await git.run "blame -L#{current_line+1},#{current_line+1} --porcelain -- #{uri.fsPath}", current_line_repo_index).split('\n')
			return hide_blame() if not blamed
			# apparently impossible to get the short form right away in easy machine readable format?
			current_line_long_hash = blamed[0].slice(0, 40)
			author = blamed[1].slice(7)
			time = relative_time.from(blamed[3].slice(12)*1000)
			status_bar_item_blame.text = "$(git-commit) #{author}, #{time}"
		), 150
	context.subscriptions.push vscode.commands.registerCommand BLAME_CMD, =>
		log.appendLine 'blame cmd'
		return if not current_line_long_hash
		state('selected-repo-index').set(current_line_repo_index)
		focus_commit_hash = (await git.run "rev-parse --short #{current_line_long_hash}").trim() # todo error here goes unnoticed
		current_line_long_hash = ''
		state('repo:selected-commits-hashes').set([focus_commit_hash])
		vscode.commands.executeCommand(START_CMD)
		push_message_id 'scroll-to-selected-commit'

	# public api of this extension:
	{ git, post_message, webview_container, context, state }

module.exports.deactivate = =>
	log.appendLine("extension deactivate")