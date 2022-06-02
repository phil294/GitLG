vscode = require 'vscode'
git = require './git'

EXT_NAME = 'git log --graph'

module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	context.subscriptions.push vscode.commands.registerCommand 'git-log--graph.start', =>
		view = vscode.window.createWebviewPanel(EXT_NAME, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { enableScripts: true, retainContextWhenHidden: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist'), vscode.Uri.joinPath(context.extensionUri, 'media') ] }).webview

		``###* @typedef {{ command: 'response', data?: any, error?: any, id: number }} MsgResponse ###
		``###* @typedef {{ command: string, data: any, id: number }} MsgRequest ###
		view.onDidReceiveMessage (###* @type MsgRequest ### message) =>
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
					h => git.exec message.data, vscode.workspace.workspaceFolders[0]?.uri.path # todo or settings, and choosable
				when 'show-error-message'
					h => vscode.window.showErrorMessage message.data
				when 'show-information-message'
					h => vscode.window.showInformationMessage message.data

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