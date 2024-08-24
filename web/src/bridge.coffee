/** @typedef {import('@extension/extension').BridgeMessage} BridgeMessage */

let vscode = acquireVsCodeApi()

/** @type {Record<string, (r: BridgeMessage) => void>} */
let response_handlers = {}
let id = 0

/** @type {Record<string, (r: BridgeMessage) => void>} */
let push_handlers = {}

window.addEventListener('message', (msg_event) => {
	/** @type BridgeMessage */
	let message = msg_event.data
	switch (message.type) {
	case 'response': if (! response_handlers[message.id])
		throw new Error('unhandled message response id: ' + JSON.stringify(message))
		response_handlers[message.id](message)
		return delete response_handlers[message.id]
	case 'push': if (! push_handlers[message.id])
		throw new Error('unhandled message push id: ' + JSON.stringify(message))
		return push_handlers[message.id](message)
	}
})

export let exchange_message = async (/** @type string */ command, /** @type any */ data) => {
	id++
	/** @type BridgeMessage */
	let request = { command, data, id, type: 'request' }
	vscode.postMessage(request)
	/** @type {BridgeMessage} */
	let resp = await new Promise((ok) => {
		response_handlers[id] = function(data) {
			return ok(data)
		}
	})
	console.info('exchange_message', command, data) // , resp

	if (resp.error) {
		let error = new Error(JSON.stringify({ error_response: resp.error, request }))
		// @ts-ignore because we need the above info (esp. request) available in the error msg

		// so it's shown in error popups etc., but the actual response message should also

		// be retrievable easily from the caller with a try-catch without the need for

		// extra json.parse, so adding this as an extra property seems like the best solution.

		error.message_error_response = resp.error
		throw error
	}
	return resp.data
}

/** @return {Promise<string>} */
export let git = async (/** @type string */ args) =>
	((await exchange_message('git', args))).trim()
export let show_information_message = (/** @type string */ msg) =>
	exchange_message('show-information-message', msg)
export let show_error_message = (/** @type string */ msg) =>
	exchange_message('show-error-message', msg)

export let add_push_listener = (/** @type string */ id, /** @type {(r: BridgeMessage) => void} */ handler) =>
	push_handlers[id] = handler
