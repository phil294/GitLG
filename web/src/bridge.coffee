###* @typedef {import('@extension/extension.coffee').BridgeMessage} BridgeMessage ###

vscode = acquireVsCodeApi()

###* @type {Record<string, (r: BridgeMessage) => void>} ###
response_handlers = {}
id = 0

###* @type {Record<string, (r: BridgeMessage) => void>} ###
push_handlers = {}

window.addEventListener 'message', (msg_event) =>
	###* @type BridgeMessage ###
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
	id++
	###* @type BridgeMessage ###
	request = { command, data, id, type: 'request' }
	vscode.postMessage request
	###* @type {BridgeMessage} ###
	resp = await new Promise (ok) =>
		response_handlers[id] = (data) =>
			ok data
	console.info "exchange_message", command, data # , resp
	if resp.error
		error = new Error(JSON.stringify({ error_response: resp.error, request }))
		# @ts-ignore because we need the above info (esp. request) available in the error msg
		# so it's shown in error popups etc., but the actual response message should also
		# be retrievable easily from the caller with a try-catch without the need for
		# extra json.parse, so adding this as an extra property seems like the best solution.
		error.message_error_response = resp.error
		throw error
	resp.data

###* @return {Promise<string>} ###
export git = (###* @type string ### args) =>
	(await exchange_message 'git', args).trim()
export show_information_message = (###* @type string ### msg) =>
	exchange_message 'show-information-message', msg
export show_error_message = (###* @type string ### msg) =>
	exchange_message 'show-error-message', msg

export add_push_listener = (###* @type string ### id, ###* @type {(r: BridgeMessage) => void} ### handler) =>
	push_handlers[id] = handler