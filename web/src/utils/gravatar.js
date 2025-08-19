import { md5_hash } from '../bridge'

/**
 * Avatar cache with localStorage persistence
 */
class AvatarCache {
	constructor() {
		this.cache_key = 'gitlg_avatar_cache'
		this.expiry_days = 7
	}

	/**
	 * Get cached avatar
	 * @param {string} email_hash
	 * @returns {string|null} base64 image data or null if not cached/expired
	 */
	get(email_hash) {
		try {
			let cache = JSON.parse(localStorage.getItem(this.cache_key) || '{}')
			let entry = cache[email_hash]

			if (! entry)
				return null

			let now = Date.now()
			let expiry = entry.timestamp + (this.expiry_days * 24 * 60 * 60 * 1000)

			if (now > expiry) {
				delete cache[email_hash]
				localStorage.setItem(this.cache_key, JSON.stringify(cache))
				return null
			}

			return entry.data
		} catch (e) {
			console.warn('Failed to read avatar cache:', e)
			return null
		}
	}

	/**
	 * Store avatar in cache
	 * @param {string} email_hash
	 * @param {string} base64_data
	 */
	set(email_hash, base64_data) {
		try {
			let cache = JSON.parse(localStorage.getItem(this.cache_key) || '{}')
			cache[email_hash] = {
				data: base64_data,
				timestamp: Date.now(),
			}
			localStorage.setItem(this.cache_key, JSON.stringify(cache))
		} catch (e) {
			console.warn('Failed to write avatar cache:', e)
		}
	}

	/**
	 * Clear expired entries from cache
	 */
	cleanup() {
		try {
			let cache = JSON.parse(localStorage.getItem(this.cache_key) || '{}')
			let now = Date.now()
			let expiry_time = this.expiry_days * 24 * 60 * 60 * 1000
			let cleaned = false

			for (let hash in cache)
				if (now > cache[hash].timestamp + expiry_time) {
					delete cache[hash]
					cleaned = true
				}

			if (cleaned)
				localStorage.setItem(this.cache_key, JSON.stringify(cache))
		} catch (e) {
			console.warn('Failed to cleanup avatar cache:', e)
		}
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

		img.onerror = () => reject(new Error('Failed to load image'))
		img.src = url
	})
}

/**
 * Get Gravatar URL for email
 * @param {string} email
 * @param {number} size
 * @returns {Promise<string>}
 */
async function get_gravatar_url(email, size = 32) {
	let hash = await md5_hash(email)
	return `https://www.gravatar.com/avatar/${hash}?s=${size}&d=identicon&r=pg`
}

/**
 * Get avatar for email with caching
 * @param {string} email
 * @returns {Promise<string|null>} base64 data URL or null
 */
export async function get_avatar(email) {
	if (! email)
		return null

	let hash = await md5_hash(email)

	// Check cache first
	let cached = avatar_cache.get(hash)
	if (cached)
		return cached

	try {
		let gravatar_url = await get_gravatar_url(email)
		let base64_data = await image_to_base64(gravatar_url)

		// Cache the result
		avatar_cache.set(hash, base64_data)

		return base64_data
	} catch (e) {
		console.warn('Failed to fetch avatar for:', email, e)
		return null
	}
}

// Cleanup expired cache entries on load
avatar_cache.cleanup()
