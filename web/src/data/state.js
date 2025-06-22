import { computed, nextTick, shallowRef } from 'vue'
import { add_push_listener, exchange_message } from '../bridge'

/** @type {Record<string, State<any>>} */ // TODO: type-safe
let _states = {}
add_push_listener('state-update', ({ data: { key, value } }) => {
	if (_states[key]) {
		_states[key]._internal.value = value // Skip the unnecessary roundtrip to backend
		_states[key].ref.value = value
	}
})
/**
 * @template T
 * This utility returns a `WritableComputed` that will persist its state or react to changes on the
 * backend somehow. The caller doesn't know where it's stored though, this is up to extension.js
 * to decide based on the *key*.
 * TODO: what if default_value omitted? / make arg required
 */
let state = (/** @type {string} */ key, /** @type {T} */ default_value, /** @type {()=>any} */ on_load = () => {}) => {
	/** @type {State<T>|undefined} */ // TODO: type-safe
	let ret = _states[key]
	if (ret) {
		nextTick()
			.then(on_load)
		return ret
	}
	// shallow because type error https://github.com/vuejs/composition-api/issues/483
	let _internal = shallowRef(default_value)
	ret = {
		ref: computed({
			get: () => _internal.value,
			set(/** @type {T} */ value) {
				if (_internal.value !== value)
					exchange_message('set-state', { key, value })
				_internal.value = value
			},
		}),
		reload: async () => {
			_internal.value = default_value
			let stored = await exchange_message('get-state', key)
			if (stored != null)
				_internal.value = stored
		},
		_internal,
	}
	_states[key] = ret;
	(async () => {
		await ret.reload()
		await nextTick()
		on_load?.()
	})()
	return ret
}

export default state

// TODO: make all state type-safe ext+web
export let refresh_repo_states = () => {
	for (let key of ['repo:action-history', 'repo:selected-commits-hashes'])
		_states[key]?.reload()
}
