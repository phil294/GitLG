/** @returns {val is Record<string, unknown>} */
export default function is_object(/** @type {unknown} */ val) {
	return val !== null && typeof val === 'object' && ! Array.isArray(val)
}
export function as_object_or_null(/** @type {unknown} */ val) {
	return is_object(val) ? val : null
}
