let vscode = acquireVsCodeApi()

/** @type {Record<string, (r: BridgeMessage) => void>} */
let response_handlers = {}
let message_id_counter = 0

/** @type {Record<string, (r: BridgeMessage) => void>} */
let push_handlers = {}

window.addEventListener('message', (msg_event) => {
	/** @type {BridgeMessage} */
	let message = msg_event.data
	switch (message.type) {
		case 'response-to-web': {
			let handler = response_handlers[message.id]
			if (! handler)
				// Can't figure out why, but sometimes a very out of order ID appears out of nowhere
				return console.warn('unhandled message response id:', message)
			handler(message)
			delete response_handlers[message.id]
			break
		}
		case 'push-to-web': {
			let handler = push_handlers[message.id]
			if (! handler)
				throw new Error('unhandled message push id: ' + JSON.stringify(message))
			handler(message)
			break
		}
	}
})

export let exchange_message = async (/** @type {string} */ command, /** @type {any} */ data) => {
	message_id_counter++
	/** @type {BridgeMessage} */
	let request = { command, data, id: message_id_counter, type: 'request-from-web' }
	vscode.postMessage(request)
	/** @type {BridgeMessage} */
	let resp = await new Promise((ok) => {
		response_handlers[message_id_counter] = ok
	})
	// console.info('exchange_message', command, data) // , resp

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

export let git = (/** @type {string} */ args, /** @type {{ignore_errors?: boolean}} */ { ignore_errors } = {}) =>
	exchange_message('git', { args, ignore_errors }).then((/** @type {string} */ s) => s.trim())
export let show_information_message = (/** @type {string} */ msg) =>
	exchange_message('show-information-message', msg)
export let show_error_message = (/** @type {string} */ msg) =>
	exchange_message('show-error-message', msg)

export let add_push_listener = (/** @type {string} */ id, /** @type {(r: BridgeMessage) => void} */ handler) =>
	push_handlers[id] = handler
