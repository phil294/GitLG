import { ref } from 'vue'

export default (/** @type {Promise<string> | undefined} */ promise) => {
	if (! promise)
		return ''
	let resolved = ref('Loading...')
	promise.then(v => resolved.value = v)
	return resolved
}
