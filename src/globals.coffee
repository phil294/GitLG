String.prototype.hashCode = function() {
	let ref, x
	let hash = 0
	if (this.length === 0)
		return hash
	for (let [i, _] of Object.entries(this)) {
		let chr = this.charCodeAt(i)
		hash = (hash << 5) - hash + chr
		hash |= 0
	}

	return hash
}

/** Call this with *args* and silently return `undefined` on error. */
Function.prototype.maybe = function(args) {
	try {
		return this(...args)
	} catch (error) {
		return undefined
	}
}

/** Catch and ignore. Like `.catch(() => undefined)`. */
Promise.prototype.maybe = function() {
	return this.catch(() => {})
}
