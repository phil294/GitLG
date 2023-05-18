import Vue from 'vue'

``###* @typedef {{label:string,icon?:string,action:()=>any}} ContextMenuEntry ###
``###* @typedef {{
	oncontextmenu: (this: HTMLElement, ev: MouseEvent) => any
	destroy: () => any
	entries_provider: (ev: MouseEvent) => ContextMenuEntry[]
}} ContextMenuData
###

``###* @type {Map<HTMLElement,ContextMenuData>} ### 
context_menu_data_by_el = new Map

remove_all_context_menus = =>
	context_menu_data_by_el.forEach (menu) =>
		menu.destroy()
document.addEventListener 'contextmenu', remove_all_context_menus, false
document.addEventListener 'click', remove_all_context_menus, false
document.addEventListener 'keyup', remove_all_context_menus, false

set_context_menu = (###* @type HTMLElement ### el, ###* @type {(ev: MouseEvent)=>ContextMenuEntry[]} ### entries_provider) =>
	existing_context_menu_data = context_menu_data_by_el.get el
	if existing_context_menu_data
		existing_context_menu_data.entries_provider = entries_provider
		return

	``###* @type {HTMLElement | null} ###
	wrapper_el = null

	# The element(s) created by this is quite similar to the template of <git-action-button>
	build_context_menu = (###* @type MouseEvent ### event) =>
		entries = entries_provider(event)
		return if not entries or wrapper_el
		wrapper_el = document.createElement('ul')
		wrapper_el.setAttribute('aria-label', 'Context menu')
		wrapper_el.classList.add 'context-menu-wrapper'
		wrapper_el.style.setProperty 'left', event.clientX + 'px'
		wrapper_el.style.setProperty 'top', event.clientY + 'px'
		entries.forEach (entry) =>
			entry_el = document.createElement('li')
			entry_el.setAttribute('role', 'button')
			entry_el.classList.add('row', 'gap-5')
			icon_el = document.createElement('i')
			if entry.icon
				icon_el.classList.add "codicon", "codicon-#{entry.icon}"
			label_el = document.createElement('span')
			label_el.textContent = entry.label
			entry_el.appendChild(icon_el)
			entry_el.appendChild(label_el)
			entry_el.onmouseup = (e) =>
				entry.action() if e.button == 0
			wrapper_el?.appendChild(entry_el)
		document.body.appendChild(wrapper_el)
	
	``###* @type ContextMenuData ###
	context_menu_data =
		oncontextmenu: (e) =>
			e.preventDefault()
			e.stopPropagation()
			remove_all_context_menus()
			build_context_menu(e)
		destroy: =>
			return if not wrapper_el
			document.body.removeChild(wrapper_el)
			wrapper_el = null
		entries_provider: entries_provider
	el.addEventListener 'contextmenu', context_menu_data.oncontextmenu, false
	context_menu_data_by_el.set el, context_menu_data

disable_context_menu = (###* @type {HTMLElement} ### el) =>
	context_menu_data = context_menu_data_by_el.get el
	if not context_menu_data
		return
	el.removeEventListener 'contextmenu', context_menu_data.oncontextmenu
	context_menu_data_by_el.delete el

``###* @type {Vue.Directive} ###
directive =
	mounted: (el, { value }) ->
		if value
			set_context_menu el, value
	updated: (el, { value }) ->
		value = value or null
		if not value
			disable_context_menu el
		else
			set_context_menu el, value
	unmounted: (el) ->
		disable_context_menu el

export default directive
