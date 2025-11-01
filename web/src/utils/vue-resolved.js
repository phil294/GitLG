import { ref } from 'vue'

export default (/** @type {Promise<any> | undefined} */ promise) => {
	if (! promise)
		return ''
	let resolved = ref('Loading...')
	promise.then(v => resolved.value = v)
	return resolved
}
