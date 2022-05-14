vscode = require 'vscode'

EXT_NAME = 'git log --graph'
VIEW_ID = 'git-log--graph'

module.exports.activate = (###* @type vscode.ExtensionContext ### context) =>
	context.subscriptions.push vscode.commands.registerCommand 'git-log--graph.start', =>
		view = vscode.window.createWebviewPanel(VIEW_ID, EXT_NAME, vscode.window.activeTextEditor?.viewColumn or 1, { enableScripts: true, localResourceRoots: [ vscode.Uri.joinPath(context.extensionUri, 'web-dist') ] }).webview

		view.onDidReceiveMessage (message) =>
			switch message.command
				when 'ready'
					view.postMessage command: 'commits', data: [
						'bar'
					]

		get_uri = (###* @type {string[]} ### ...path_segments) =>
			view.asWebviewUri vscode.Uri.joinPath context.extensionUri, ...path_segments
		view.html = "
			<!DOCTYPE html>
			<html lang='en'>
			<head>
				<meta charset='UTF-8'>
				<meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; style-src #{view.cspSource}; script-src #{view.cspSource};\">
				<meta name='viewport' content='width=device-width, initial-scale=1.0'>
				<link href='#{get_uri 'web-dist', 'css', 'app.css'}' rel='stylesheet'>
				<title>#{EXT_NAME}</title>
			</head>
			<body>
				<div id='app'></div>

				<script src='#{get_uri 'web-dist', 'js', 'chunk-vendors.js'}'></script>
				<script src='#{get_uri 'web-dist', 'js', 'app.js'}'></script>
			</body>
			</html>"