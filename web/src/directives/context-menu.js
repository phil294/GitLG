import { VscodeContextMenu } from '@vscode-elements/elements'

/** @typedef {{label:string,icon?:string,action:()=>any}} ContextMenuEntry */
/**
@typedef {{
	oncontextmenu: (this: HTMLElement, ev: MouseEvent) => any
	destroy: () => any
	entries_provider: (ev: MouseEvent) => ContextMenuEntry[]
}} ContextMenuData
 */

/** @type {Map<HTMLElement,ContextMenuData>} */
let context_menu_data_by_el = new Map()

function remove_all_context_menus() {
	context_menu_data_by_el.forEach((menu) =>
		menu.destroy())
}
document.addEventListener('contextmenu', remove_all_context_menus, false)
document.addEventListener('click', remove_all_context_menus, false)
document.addEventListener('keyup', remove_all_context_menus, false)

function set_context_menu(/** @type {HTMLElement} */ el, /** @type {(ev: MouseEvent)=>ContextMenuEntry[]} */ entries_provider) {
	let existing_context_menu_data = context_menu_data_by_el.get(el)
	if (existing_context_menu_data) {
		existing_context_menu_data.entries_provider = entries_provider
		return
	}

	/** @type {VscodeContextMenu | null} */
	let wrapper_el = null

	// The element(s) created by this is quite similar to the template of <git-action-button>
	function build_context_menu(/** @type {MouseEvent} */ event) {
		let entries = entries_provider(event)
		if (! entries || wrapper_el)
			return
		wrapper_el = document.createElement('vscode-context-menu')
		wrapper_el.setAttribute('aria-label', 'Context menu')
		wrapper_el.style.setProperty('left', event.clientX + 'px')
		wrapper_el.style.setProperty('top', event.clientY + 'px')

		// Unfortunately, using wrapper_el.data.push breaks hovering, so we have to create a new array
		wrapper_el.data = entries.map((entry) => ({
			label: entry.label,
			value: entries.indexOf(entry).toString(),
		}))
		wrapper_el.addEventListener('vsc-context-menu-select', (selectEvent) => {
			entries[parseInt(selectEvent.detail.value)]?.action()
		})
		wrapper_el.show = true
		document.body.appendChild(wrapper_el)

		// Hack some icons in
		// We'll need to wait for the context menu items to be available
		requestAnimationFrame(() => {
			if (! wrapper_el || ! wrapper_el.shadowRoot)
				return

			const items = wrapper_el.shadowRoot.querySelectorAll('vscode-context-menu-item')
			entries.forEach((entry, index) => {
				const shadowRoot = items[index]?.shadowRoot
				if (! shadowRoot)
					return

				// vscode-elements goes against vscode's cursor for context menu items
				shadowRoot.querySelector('a').style.cursor = 'pointer'

				if (! entry.icon)
					return

				// I feel like the padding vscode-elements uses doesn't match the padding vscode uses
				// So I tried to match it as best as I could
				const icon = document.createElement('vscode-icon')
				icon.name = entry.icon
				icon.style.position = 'absolute'
				icon.style.left = '4px'
				shadowRoot.querySelector('.label').style.paddingLeft = '2em'
				shadowRoot?.querySelector('a')?.prepend(icon)
			})
		})
	}

	/** @type {ContextMenuData} */
	let context_menu_data = {
		oncontextmenu(e) {
			e.preventDefault()
			e.stopPropagation()
			remove_all_context_menus()
			build_context_menu(e)
		},
		destroy() {
			if (! wrapper_el)
				return
			document.body.removeChild(wrapper_el)
			wrapper_el = null
		},
		entries_provider,
	}
	el.addEventListener('contextmenu', context_menu_data.oncontextmenu, false)
	context_menu_data_by_el.set(el, context_menu_data)
}

function disable_context_menu(/** @type {HTMLElement} */ el) {
	let context_menu_data = context_menu_data_by_el.get(el)
	if (! context_menu_data)
		return
	el.removeEventListener('contextmenu', context_menu_data.oncontextmenu)
	context_menu_data_by_el.delete(el)
}

/** @type {Vue.Directive} */
let directive = {
	mounted(el, { value }) {
		if (value)
			set_context_menu(el, value)
	},
	updated(el, { value }) {
		value = value || null
		if (! value)
			disable_context_menu(el)
		else
			set_context_menu(el, value)
	},
	unmounted(el) {
		disable_context_menu(el)
	},
}

export default directive
