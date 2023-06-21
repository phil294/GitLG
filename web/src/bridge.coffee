``###* @typedef {import('@extension/extension.coffee').BridgeMessage} BridgeMessage ###

vscode = acquireVsCodeApi()

``###* @type {Record<string, (r: BridgeMessage) => void>} ###
response_handlers = {}
id = 0

``###* @type {Record<string, (r: BridgeMessage) => void>} ###
push_handlers = {}

window.addEventListener 'message', (msg_event) =>
	``###* @type BridgeMessage ###
	message = msg_event.data
	switch message.type
		when 'response'
			throw new Error "unhandled message response id: " + JSON.stringify(message) if not response_handlers[message.id]
			response_handlers[message.id] message
			delete response_handlers[message.id]
		when 'push'
			throw new Error "unhandled message push id: " + JSON.stringify(message) if not push_handlers[message.id]
			push_handlers[message.id] message

export exchange_message = (###* @type string ### command, ###* @type any ### data) =>
	console.info "exchange_message", command, data
	id++
	``###* @type BridgeMessage ###
	request = { command, data, id, type: 'request' }
	vscode.postMessage request
	``###* @type {BridgeMessage} ###
	resp = await new Promise (ok) =>
		response_handlers[id] = (data) =>
			ok data
	if resp.error then throw resp.error
	resp.data

``###* @return {Promise<string>} ###
export git = (###* @type string ### args) =>
	(await exchange_message 'git', args).trim()
export show_information_message = (###* @type string ### msg) =>
	exchange_message 'show-information-message', msg
export show_error_message = (###* @type string ### msg) =>
	exchange_message 'show-error-message', msg

export add_push_listener = (###* @type string ### id, ###* @type {(r: BridgeMessage) => void} ### handler) =>
	push_handlers[id] = handler