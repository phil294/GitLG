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

Function.prototype.maybe = function(/** @type {Array<any>} */ args = []) {
	try {
		return this(...args)
	} catch (error) {
		return undefined
	}
}

Promise.prototype.maybe = function() {
	return this.catch(() => undefined)
}

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
