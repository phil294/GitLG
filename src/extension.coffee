vscode = require 'vscode'
util = require('util')
exec = util.promisify(require('child_process').exec)

EXT_NAME = 'git log --graph'

git = (###* @type string ### args) =>
	{ stdout, stderr } = await exec 'git ' + args,
		cwd: vscode.workspace.workspaceFolders?[0].uri.path # todo or settings, and choosable
		# 35 MB. For scale, Linux kernel git graph (1 mio commits) in extension format is 538 MB or 7.4 MB for the first 15k commits
		maxBuffer: 1024 * 1024 * 35
	stdout

module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	context.subscriptions.push vscode.workspace.registerTextDocumentContentProvider 'git-show',
		provideTextDocumentContent: (uri) ->
			(try await git "show #{uri.path}") or ''

	context.subscriptions.push vscode.commands.registerCommand 'git-log--graph.start', =>
		view = vscode.window.createWebviewPanel(EXT_NAME, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { enableScripts: true, retainContextWhenHidden: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist'), vscode.Uri.joinPath(context.extensionUri, 'media') ] }).webview

		``###* @typedef {{ command: 'response', data?: any, error?: any, id: number }} MsgResponse ###
		``###* @typedef {{ command: string, data: any, id: number }} MsgRequest ###
		view.onDidReceiveMessage (###* @type MsgRequest ### message) =>
			d = message.data
			h = (###* @type {() => any} ### func) =>
				``###* @type MsgResponse ###
				resp =
					command: 'response'
					id: message.id
				try
					resp.data = await func()
				catch e
					resp.error = e
				view.postMessage resp
			switch message.command
				when 'git'
					h => git d
				when 'show-error-message'
					h => vscode.window.showErrorMessage d
				when 'show-information-message'
					h => vscode.window.showInformationMessage d
				when 'get-config'
					h => context.globalState.get d
				when 'set-config'
					h => context.globalState.update d.key, d.value
				when 'open-diff'
					h =>
						uri_1 = vscode.Uri.parse "git-show:#{d.hash}~1:#{d.filename}"
						uri_2 = vscode.Uri.parse "git-show:#{d.hash}:#{d.filename}"
						vscode.commands.executeCommand 'vscode.diff', uri_1, uri_2, "#{d.filename} @#{d.hash}"

		get_uri = (###* @type {string[]} ### ...path_segments) =>
			view.asWebviewUri vscode.Uri.joinPath context.extensionUri, ...path_segments
		view.html = "
			<!DOCTYPE html>
			<html lang='en'>
			<head>
				<meta charset='UTF-8'>
				<meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; style-src #{view.cspSource} 'unsafe-inline'; script-src #{view.cspSource}; font-src #{view.cspSource};\">
				<meta name='viewport' content='width=device-width, initial-scale=1.0'>
				<link href='#{get_uri 'web-dist', 'css', 'app.css'}' rel='stylesheet'>
				<style>
					@font-face {
						font-family: 'OverpassMono-Bold';
						src: url('#{get_uri 'media'}/OverpassMono-Bold.ttf') format('truetype');
					}
				</style>
				<title>#{EXT_NAME}</title>
			</head>
			<body>
				<div id='app'></div>
				<script src='#{get_uri 'web-dist', 'js', 'chunk-vendors.js'}'></script>
				<script src='#{get_uri 'web-dist', 'js', 'app.js'}'></script>
			</body>
			</html>"