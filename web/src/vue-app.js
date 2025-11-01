import { show_error_message, show_information_message } from './bridge.js'
import { createApp } from 'vue'
import '../../src/globals'
// @ts-ignore TODO: idk
import App from './App.vue'
import { RecycleScroller } from 'vue-virtual-scroller'
import 'vue-virtual-scroller/dist/vue-virtual-scroller.css'
import '@vscode/codicons/dist/codicon.css'

let console_error = console.error
function handle_error(/** @type {any[]} */ ...args) {
	let prompt_error = args.map((x) =>
		typeof x === 'string' ? x : x ? (
			/* Proxied Vue render function. Accessing normal props results in more intermediate console errors, so this catches them and also provides the component name. This requires source maps to be disabled in production in order to work there. */
			x.$?.type?.__name ||
			/* standard props poking in the dark */
			x.message || x.msg || x.data || x.body || x.stack || (() => { try { return JSON.stringify(x, null, 4) } catch (_) { return 0 } })() || x.toString?.())?.toString?.() : '-')
		.join('\n')
	let $el = args[0]?.domChain || args[1]?.$el
	// if (! args[0]?.message_error_response)
	console_error(...args, new Error(), $el ? ['at element', $el] : '')
	console.trace()
	// debugger // eslint-disable-line no-debugger
	show_error_message(prompt_error)
}
window.onerror = handle_error
console.error = handle_error
window.addEventListener('unhandledrejection', (e) =>
	handle_error(e.reason))

// this doesn't work, even the overridden calls are blocked by vscode
window.alert = show_information_message

let app = createApp(App)

app.config.errorHandler = handle_error
app.config.warnHandler = handle_error

// When adding global components here, also change in vite-config > components.d.ts
app.component('RecycleScroller', RecycleScroller)

// These are auto-added to type decl
let sfcs = import.meta.glob('./**/*.vue', { eager: true })
for (let path in sfcs)
	app.component(path.split('/').pop()?.split('.')[0] || '???', /** @type {any} */ (sfcs)[path].default)

app.mount('#app')
