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

send_message = (###* @type string ### command, ###* @type any ### data) =>
	console.info "send_message", command, data
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
	(await send_message 'git', args).trim()
export show_information_message = (###* @type string ### msg) =>
	send_message 'show-information-message', msg
export show_error_message = (###* @type string ### msg) =>
	send_message 'show-error-message', msg
export get_global_state = (###* @type string ### key) =>
	send_message 'get-global-state', key
export set_global_state = (###* @type string ### key, ###* @type any ### value) =>
	send_message 'set-global-state', { key, value }
export open_diff = (###* @type string ### hash, ###* @type string ### filename) =>
	send_message 'open-diff', { hash, filename }
export get_config = (###* @type string ### key) =>
	send_message 'get-config', key
``###* @return {Promise<string[]>} ###
export get_folder_names = =>
	send_message 'get-folder-names'
export set_selected_folder_index = (###* @type number ### i) =>
	send_message 'set-selected-folder-index', i
export get_selected_folder_index = =>
	Number((await send_message 'get-selected-folder-index'))

export add_push_listener = (###* @type string ### id, ###* @type {(r: BridgeMessage) => void} ### handler) =>
	push_handlers[id] = handler