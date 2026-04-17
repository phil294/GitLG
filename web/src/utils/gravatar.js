import { sha256_hash } from '../bridge'

/** localStorage persisted */
class AvatarCache {
	constructor() {
		this.cache_key = 'gitlg_avatar_cache'
		this.expiry_days = 7
		this.cache = JSON.parse(localStorage.getItem(this.cache_key) || '{}')
	}
	#write_cache() {
		// Only not non-nulls are stored so http errors are retried at next extension reload
		localStorage.setItem(this.cache_key, JSON.stringify(Object.fromEntries(Object.entries(this.cache).filter(([_hash, value]) =>
			value))))
	}
	/** @returns base64 image data or null if prior request failed or undefined if not yet cached */
	get(/** @type {string} */ email_hash) {
		return this.cache[email_hash] ? this.cache[email_hash].data : this.cache[email_hash]
	}
	set(/** @type {string} */ email_hash, /** @type {string | null} */ base64_data) {
		this.cache[email_hash] = base64_data === null
			? null : {
				data: base64_data,
				timestamp: Date.now(),
			}

		this.#write_cache()
	}
	// TODO: test
	/** Clear expired entries from cache */
	cleanup() {
		let now = Date.now()
		let expiry_time = this.expiry_days * 24 * 60 * 60 * 1000
		this.cache = Object.fromEntries(Object.entries(this.cache).filter(([_hash, value]) =>
			value?.timestamp != null && now < value.timestamp + expiry_time))
		this.#write_cache()
	}
}

let avatar_cache = new AvatarCache()

/**
 * Convert image URL to base64 data URL
 * @param {string} url
 * @returns {Promise<string>}
 */
async function image_to_base64(url) {
	return new Promise((resolve, reject) => {
		let img = new Image()
		img.crossOrigin = 'anonymous'

		img.onload = () => {
			let canvas = document.createElement('canvas')
			let ctx = canvas.getContext('2d')

			if (! ctx) {
				reject(new Error('Could not get canvas context'))
				return
			}

			canvas.width = img.width
			canvas.height = img.height

			ctx.drawImage(img, 0, 0)

			try {
				let data_url = canvas.toDataURL('image/png')
				resolve(data_url)
			} catch (e) {
				reject(e)
			}
		}

		img.onerror = () => { reject(new Error('Failed to load image')) }
		img.src = url
	})
}

/**
 * Get avatar for email with caching
 * @param {string} email
 * @returns {Promise<string|null>} base64 data URL or null
 */
export async function get_avatar(email) {
	if (! email)
		return null

	let hash = await sha256_hash(email.trim().toLowerCase())

	let cached = avatar_cache.get(hash)
	if (cached !== undefined)
		return cached

	try {
		let gravatar_url = `https://www.gravatar.com/avatar/${hash}?s=32&d=identicon&r=pg`
		let base64_data = await image_to_base64(gravatar_url)

		avatar_cache.set(hash, base64_data)

		return base64_data
	} catch (e) {
		console.warn('Failed to fetch avatar for:', email, e)
		avatar_cache.set(hash, null)
		return null
	}
}

// Cleanup expired cache entries on load
avatar_cache.cleanup()
