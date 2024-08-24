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
	return this.catch(() => {})
}
