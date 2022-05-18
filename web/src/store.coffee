#
###* @type {import('vscode-webview').WebviewApi<unknown>} ###
vscode = acquireVsCodeApi?() or
	# fallback for developing in browser
	postMessage: ({ command }) =>
		console.log "post message #{command}"
	getState: =>
	setState: (_) => _

#
###* @type {{[id: number]: (data: any) => void }} ###
callbacks = {}
id = 0

#
###*
# @param args {string}
# @returns {Promise<string>}
###
export git = (args) =>
	answer = new Promise (ok) =>
		callbacks[++id] = (data) =>
			ok data
	vscode.postMessage { command: 'git', args, id }
	resp = await answer
	resp.data or throw resp.error
#
###* @param msg {string} ###
export show_information_message = (msg) =>
	vscode.postMessage { command: 'show-information-message', msg }
#
###* @param msg {string} ###
export show_error_message = (msg) =>
	vscode.postMessage { command: 'show-error-message', msg }

window.addEventListener 'message', ({ data: message }) =>
	switch message.command
		when 'response'
			handler = callbacks[message.id]
			if handler
				handler message.payload
				delete callbacks[message.id]
			else
				throw new Error "unhandled response id: " + JSON.stringify(message)