export default (/** @type {string} */ str) =>
	str.replaceAll('\\', '\\\\').replaceAll('"', '\\"')
