String.prototype.hashCode = function() {
	let hash = 0
	if (this.length === 0)
		return hash
	for (let i = 0; i < this.length; i++) {
		let chr = this.charCodeAt(i)
		hash = (hash << 5) - hash + chr
		hash |= 0
	}
	return hash
}

/**
 * To use in place of TypeScript's `!` operator
 * @template T
 * @param value {T | undefined | null}
 */
globalThis.not_null = (value) => {
	if (value == null)
		throw new Error(`not_null assertion failed for ${value}`)
	return value
}

globalThis.sleep = (/** @type {number} */ ms) =>
	new Promise(bingbong =>
		setTimeout(bingbong, ms))

/**
 * To use in place of `.filter(Boolean)` for type safety with strict null checks.
 * @template T
 * @param value {T | undefined | null | false}
 * @returns {value is T}
 */
globalThis.is_truthy = (value) => !! value

/** @returns {ref is Branch} */
globalThis.is_branch = (/** @type {GitRef} */ ref) =>
	ref.type === 'branch'

/** @type {Record<number,NodeJS.Timeout>} */
const debounce_timeout_map = {}
/** relies on the unique hash value of *fun*, so use with care */
globalThis.debounce = (/** @type {()=>any} */ fun, /** @type {number} */ time) => {
	let hash = (fun.toString() + time).hashCode()
	clearTimeout(debounce_timeout_map[hash])
	debounce_timeout_map[hash] = setTimeout(fun, time)
}

export {}
