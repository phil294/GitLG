import { ref } from 'vue'

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

store =
	error: ref ''
	#
	###* @param args {string} ###
	do_git: (args) =>
		answer = new Promise (ok) =>
			callbacks[++id] = (data) =>
				ok data
		vscode.postMessage { command: 'git', args, id }
		resp = await answer
		resp.data or throw resp.error
	#
	###* @param args {string} ###
	do_log: (args) =>
		store.commits.value = []
		data = await store.do_git args
		store.commits.value = data.split '\n'
	commits: ref []

window.addEventListener 'message', ({ data: message }) =>
	switch message.command
		when 'response'
			handler = callbacks[message.id]
			if handler
				handler message.payload
				delete callbacks[message.id]
			else
				throw new Error "unhandled response id: " + JSON.stringify(message)

export default store