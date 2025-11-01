/** @typedef {{label:()=>Promise<string>,icon?:string,action:()=>any}} ContextMenuEntry */
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
document.addEventListener('keydown', (event) => {
	if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
		let entries = document.querySelector('ul.context-menu-wrapper')?.children
		if (entries) {
			event.preventDefault()
			let i = [...entries].findIndex(e => e.classList.contains('selected'))
			if (i > -1)
				entries[i]?.classList.remove('selected')
			i += event.key === 'ArrowDown' ? 1 : -1
			if (i < 0)
				i = entries.length - 1
			else if (i >= entries.length)
				i = 0
			entries[i]?.classList.add('selected')
			return
		}
	}
	if (event.key === 'Enter' || event.key === ' ') {
		let entry = document.querySelector('ul.context-menu-wrapper > .selected')
		if (entry) {
			event.preventDefault()
			// @ts-ignore
			entry.focus()
			return
		}
	}

	remove_all_context_menus()
}, false)

function set_context_menu(/** @type {HTMLElement} */ el, /** @type {(ev: MouseEvent)=>ContextMenuEntry[]} */ entries_provider) {
	let existing_context_menu_data = context_menu_data_by_el.get(el)
	if (existing_context_menu_data) {
		existing_context_menu_data.entries_provider = entries_provider
		return
	}

	/** @type {HTMLElement | null} */
	let wrapper_el = null

	// The element(s) created by this is quite similar to the template of <git-action-button>
	async function build_context_menu(/** @type {MouseEvent} */ event) {
		let entries = entries_provider(event)
		if (! entries || wrapper_el)
			return
		wrapper_el = document.createElement('ul')
		wrapper_el.setAttribute('aria-label', 'Context menu')
		wrapper_el.classList.add('context-menu-wrapper')
		wrapper_el.style.setProperty('left', event.clientX + 'px')
		wrapper_el.style.setProperty('top', event.clientY + 'px')
		for (let entry of entries) {
			let entry_el = document.createElement('li')
			entry_el.setAttribute('role', 'button')
			entry_el.setAttribute('tabindex', '-1')
			entry_el.classList.add('row', 'gap-5', 'align-center')
			let icon_el = document.createElement('i')
			if (entry.icon)
				icon_el.classList.add('codicon', `codicon-${entry.icon}`)
			let label_el = document.createElement('span')
			label_el.textContent = await entry.label()
			entry_el.appendChild(icon_el)
			entry_el.appendChild(label_el)
			entry_el.onfocus = () => {
				entry.action()
				remove_all_context_menus()
			}
			wrapper_el?.appendChild(entry_el)
		}
		document.body.appendChild(wrapper_el)
	}

	/** @type {ContextMenuData} */
	let context_menu_data = {
		oncontextmenu(e) {
			e.preventDefault()
			e.stopPropagation()
			remove_all_context_menus() // including its own destroy() below
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
