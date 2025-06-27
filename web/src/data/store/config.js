import state from '../state'

// TODO: test with all set to null
let config = state('config', {}).ref

/** @returns {val is Record<string, unknown>} */
let is_object = (/** @type {Json | undefined} */ val) =>
	val !== null && typeof val === 'object' && ! Array.isArray(val)

let get_json = (/** @type {string} */ key) =>
	key.split('.')
		.reduce((/** @type {Json | undefined} */ acc, sub_key) =>
			is_object(acc) ? acc[sub_key] : null
		, config.value) ?? null

/** All getters support nested keys using `.` dot separation notation */
export default {
	get_string_array: (/** @type {string} */ key) => {
		let val = get_json(key)
		return Array.isArray(val) ? val.map(String) : []
	},
	get_string_map: (/** @type {string} */ key) => {
		let val = get_json(key)
		return is_object(val)
			? Object.fromEntries(Object.entries(val).map(([k, v]) =>
				[k, String(v)]))
			: {}
	},
	get_number: (/** @type {string} */ key) =>
		Number(get_json(key)) || 0,
	get_string: (/** @type {string} */ key) =>
		String(get_json(key)),
	/** Undefined necessary in case `true` is supposed to be the default */
	get_boolean_or_undefined: (/** @type {string} */ key) => {
		let val = get_json(key)
		return val === undefined ? undefined : Boolean(val)
	},
	/** @returns {ConfigGitAction[]} */
	get_git_actions: (/** @type {string} */ key) => {
		let val = get_json(key)
		if (! Array.isArray(val))
			return []
		return val.map(v => {
			if (! is_object(v))
				return null
			return {
				title: String(v.title),
				description: String(v.description),
				info: String(v.info),
				immediate: Boolean(v.immediate),
				ignore_errors: Boolean(v.ignore_errors),
				args: String(v.args),
				icon: String(v.icon),
				params: ! Array.isArray(v.params) ? [] : v.params.map(p =>
					typeof p === 'string' ? p
						: ! is_object(p) ? null
							: {
								value: String(p.value),
								multiline: Boolean(p.multiline),
								placeholder: String(p.placeholder),
								readonly: Boolean(p.readonly),
							})
					.filter(is_truthy),
				options: ! Array.isArray(v.options) ? [] : v.options.map(o =>
					! is_object(o) ? null : {
						value: String(o.value),
						default_active: Boolean(o.default_active),
						active: Boolean(o.active),
						info: String(o.info),
					}).filter(is_truthy),
			}
		}).filter(is_truthy)
	},
	_protected: {
		ref: config,
	},
}
