/**
 * @typedef {{
 *   context: import('vscode').ExtensionContext,
 *   git: ReturnType<import('./git.js').get_git>,
 *   get_config: () => import('vscode').WorkspaceConfiguration
 * }} StorageProviderContext
 */
/**
 * @template T
 * @typedef {(ctx: StorageProviderContext) => {get: () => T | undefined, set: (v: T) => void }} StorageProvider
 */

/** @satisfies {Record<string, <T>(key: string) => StorageProvider<T>>} */
let storage_providers = {
	global: (key) =>
		(ctx) => ({
			get: () => ctx.context.globalState.get(key),
			set: (v) => ctx.context.globalState.update(key, v),
		}),
	repo: (local_key) =>
		(ctx) => {
			function key() {
				// let repo = states['selected-repo-path'].storage(ctx).get() // ts can't cope with this
				let repo = ctx.context.workspaceState.get('selected-repo-path')
				let repo_name = ctx.git.get_repo_infos().find(i => i.path === repo)?.name
				if (! repo_name)
					console.warn(`Failed to get/set repo data for key ${local_key} because the current repo is not contained in the list of loaded repos for some reason`)
				return `repo-${local_key}-${repo_name}`
			}
			return {
				get: () => ctx.context.workspaceState.get(key()),
				set: (v) => ctx.context.workspaceState.update(key(), v),
			}
		},
	/** @template T */
	memory: () =>
		() => {
			/** @type {T | undefined} */
			let stored = undefined
			return {
				get: () => stored,
				set: (/** @type {T | undefined} */ v) => stored = v,
			}
		},
}

/** @satisfies {Record<string, {type: string, storage: StorageProvider<any>}>} */
let states = {
	config: {
		type: 'special',
		storage: (ctx) => ({
			get: () => ctx.get_config(),
			set() {},
		}),
	},
	'selected-repo-path': {
		type: 'special',
		storage: (ctx) => ({
			get: () => /** @type {string | undefined} */ (ctx.context.workspaceState.get('selected-repo-path')),
			set(/** @type {string} */ v) {
				ctx.context.workspaceState.update('selected-repo-path', v)
				ctx.git.set_selected_repo_path(v)
			},
		}),
	},
	'repo-infos': {
		type: 'special',
		storage: (ctx) => ({
			get: () => ctx.git.get_repo_infos(),
			set() {},
		}),
	},
	// TODO: maybe remove the repo: prefixes
	'repo:selected-commits-hashes': {
		type: 'repo',
		storage: /** @type {typeof storage_providers.repo<string[]>} */ (storage_providers.repo)('selected-commits-hashes'),
	},
	'repo:action-history': {
		type: 'repo',
		storage: /** @type {typeof storage_providers.repo<HistoryEntry[]>} */ (storage_providers.repo)('action-history'),
	},
	'web-phase': {
		type: 'memory',
		storage: /** @type {typeof storage_providers.memory<'dead' | 'initializing' | 'initializing_repo' | 'ready' | 'refreshing'>} */ (storage_providers.memory)(),
	},
	// ...TODO:
}

/** @typedef {keyof states} StateKey */
/**
 * @template {StateKey} K
 * @typedef {ReturnType<ReturnType<states[K]['storage']>['get']>} StateType
 */

/**
 * @template {StateKey} K
 * @typedef {(v: StateType<K>) => Awaited<'stay-subscribed' | 'unsubscribe'>} StateChangeListener
 */

/**
 * @param options {StorageProviderContext & {
 *   on_broadcast: <T extends StateKey>(key: T, value: StateType<T>) => void,
 * }}
 */
module.exports.get_state = ({ context, git, on_broadcast, get_config }) => {
	/** @type {{[key in StateKey]?: Array<StateChangeListener<key>>}} */
	let state_change_listeners = {}

	/**
	 * Something to be synchronized with the web view - initialization, storage,
	 * update and retrieval is supported in both directions.
	 * @template {StateKey} K
	 * @returns {{
	 *	get: () => StateType<K>,
	 *	set: (v: StateType<K>, opt?: {broadcast?: boolean}) => void
	 * }}
	 */
	function state(/** @type {K} */ key) {
		let storage = states[key].storage({ context, git, get_config })
		return {
			get: () => /** @type {StateType<K>} */ (storage.get()),
			set(/** @type {StateType<K>} */ value, options = {}) {
				// @ts-ignore TODO: idk
				storage.set(value)
				if (options.broadcast !== false)
					on_broadcast(key, value);
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
		add_state_change_listener(/** @type {StateKey} */ key, /** @type {StateChangeListener<key>} */ listener) {
			state_change_listeners[key] ||= []
			state_change_listeners[key].push(listener)
		},
	}
}
