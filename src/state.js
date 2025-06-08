/**
 * Something to be synchronized with the web view - initialization, storage,
 * update and retrieval is supported in both directions.
 * @param options {{
 *   context: import('vscode').ExtensionContext,
 *   git: ReturnType<import('./git.js').get_git>,
 *   on_broadcast: (data: {key: string, value: string}) => any,
 * }}
 */
module.exports.get_state = ({ context, git, on_broadcast }) => {
/** @typedef {(v: any) => Awaited<'stay-subscribed' | 'unsubscribe'>} StateChangeListener */
/** @type {Record<string, Array<StateChangeListener>>} */
	let state_change_listeners = {}
	/** @template T */
	function global_state_memento(/** @type {string} */ key) {
		return {
			get: () => context.globalState.get(key),
			set: (/** @type {T} */ v) => context.globalState.update(key, v),
		}
	}
	// /** @template T */
	// function workspace_state_memento(/** @type {string} */ key) {
	// 	return {
	// 		get: () => context.workspaceState.get(key),
	// 		set: (/** @type {T} */ v) => context.workspaceState.update(key, v),
	// 	}
	// }
	/** @template T */
	function repo_state_memento(/** @type {string} */ local_key) {
		function key() {
			let repo_name = git.get_repo_names()[state('selected-repo-index').get()]
			return `repo-${local_key}-${repo_name}`
		}
		return {
			get: () => context.workspaceState.get(key()),
			set: (/** @type {T} */ v) => context.workspaceState.update(key(), v),
		}
	}
	/** @template T */
	function transient_memento() {
	/** @type {T | null} */
		let stored = null
		return {
			get: () => stored,
			set: (/** @type {T} */ v) => stored = v,
		}
	}
	/** @type {Record<string, {get:()=>any,set:(value:any)=>any}>} */
	let special_states = { // "Normal" states instead are just default_memento
		'selected-repo-index': {
			get: () => context.workspaceState.get('selected-repo-index'),
			set(v) {
				context.workspaceState.update('selected-repo-index', v)
				git.set_selected_repo_index(Number(v) || 0)
				// These will have changed now, so notify clients of updated value
				for (let key of ['repo:action-history', 'repo:selected-commits-hashes'])
					state(key).set(state(key).get())
			},
		},
		'repo-names': {
			get: () => git.get_repo_names(),
			set() {},
		},
		'repo:selected-commits-hashes': repo_state_memento('selected-commits-hashes'),
		'repo:action-history': repo_state_memento('action-history'),
		'web-phase': transient_memento(),
	}
	let default_memento = global_state_memento
	function state(/** @type {string} */ key) {
		let memento = special_states[key] || default_memento(key)
		return {
			get: memento.get,
			set(/** @type {any} */ value, /** @type {{broadcast?:boolean}} */ options = {}) {
				memento.set(value)
				if (options.broadcast !== false)
					on_broadcast({ key, value });
				(state_change_listeners[key] || []).forEach(async listener => {
					let response = await listener(value)
					if (response === 'unsubscribe')
						delete state_change_listeners[key]
				})
			},
		}
	}
	return {
		state,
		add_state_change_listener(/** @type {string} */ key, /** @type {StateChangeListener} */ listener) {
			state_change_listeners[key] ||= []
			state_change_listeners[key].push(listener)
		},
	}
}
