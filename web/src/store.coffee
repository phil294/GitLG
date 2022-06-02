# todo externalize these types (shared with extension.coffee)
``###* @typedef {{ command: 'response', data?: any, error?: any, id: number }} MsgResponse ###
``###* @typedef {{ command: string, data: any, id: number }} MsgRequest ###

vscode = acquireVsCodeApi()

``###* @type {Record<string, (r: MsgResponse) => void>} ###
callbacks = {}
id = 0

window.addEventListener 'message', (msg_event) =>
	``###* @type MsgResponse ###
	message = msg_event.data
	switch message.command
		when 'response'
			handler = callbacks[message.id]
			if handler
				handler message
				delete callbacks[message.id]
			else
				throw new Error "unhandled response id: " + JSON.stringify(message)

send_message = (###* @type string ### command, ###* @type any ### data) =>
	id++
	``###* @type MsgRequest ###
	request = { command, data, id }
	vscode.postMessage request
	``###* @type {MsgResponse} ###
	resp = await new Promise (ok) =>
		callbacks[id] = (data) =>
			ok data
	if resp.error then throw resp.error
	resp.data

``###* @return {Promise<string>} ###
export git = (###* @type string ### args) =>
	(await send_message 'git', args).trim()
export show_information_message = (###* @type string ### msg) =>
	send_message 'show-information-message', msg
export show_error_message = (###* @type string ### msg) =>
	send_message 'show-error-message', msg
export get_config = (###* @type string ### key) =>
	send_message 'get-config', key
export set_config = (###* @type string ### key, ###* @type any ### value) =>
	send_message 'set-config', { key, value }
export open_diff = (###* @type string ### hash, ###* @type string ### filename) =>
	send_message 'open-diff', { hash, filename }