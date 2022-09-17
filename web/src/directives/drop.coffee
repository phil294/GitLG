import Vue from 'vue'

# For testing:
# https://jsfiddle.net/5Lmpxb1r/

###* @typedef {{ data?: any, files?: FileList, event: DragEvent }} DropCallbackPayload ###

###* @typedef {{
	ondragover: (this: HTMLElement, ev: DragEvent) => any
	ondragenter: (this: HTMLElement, ev: DragEvent) => any
	ondragleave: (this: HTMLElement, ev: DragEvent) => any
	ondrop: (this: HTMLElement, ev: DragEvent) => any
	ondrop_cb: (payload: DropCallbackPayload) => void
}} DragData
###

###* @type {Map<HTMLElement,DragData>} ### 
drag_data_by_el = new Map

set_drop = (###* @type {HTMLElement} ### el, ###* @type {(payload: DropCallbackPayload) => void} ### drop_cb) =>
	existing_drag_data = drag_data_by_el.get el
	if existing_drag_data
		existing_drag_data.ondrop_cb = drop_cb
		return

	el.classList.add 'drop-target'
	counter = 0
	
	#
	###* @type DragData ###
	drag_data =
		ondragover: (e) =>
			e.preventDefault() # allow drop
			if e.dataTransfer
				e.dataTransfer.dropEffect = 'move'
		ondragenter: (e) =>
			counter++
			if counter == 1
				# This check should be done but doesn't work as Chrome does not include
				# drag data in dragenter events.
				# json_data = try e.dataTransfer?.getData('application/json')
				# if json_data or e.dataTransfer?.files.length
				el.classList.add 'dragenter'
		ondragleave: =>
			counter--
			if counter == 0
				el.classList.remove 'dragenter'
		ondrop: (e) =>
			e.preventDefault() # prevents page redirect
			counter = 0
			el.classList.remove 'dragenter'

			# @ts-ignore
			if e. _vue_drag_processed
				return
			# Prevent duplicate drop handling with nested children:
			# Could use `e.stopPropagation()` but then how will parents know the dragging is complete?
			# There is no `dragend` (see below). So just set a flag:
			# @ts-ignore
			e._vue_drag_processed = true

			#
			###* @type DropCallbackPayload ###
			cb_payload =
				event: e
			if e.dataTransfer and e.dataTransfer.files.length
				cb_payload.files = e.dataTransfer.files
			else
				try
					# Needs to be inside try/catch because stackoverflow.com/q/65775496
					data = JSON.parse e.dataTransfer?.getData('application/json') || ''
					cb_payload.data = data
				catch e
					console.warn "Drop event does container neither files nor JSON", e
			drag_data.ondrop_cb cb_payload
		ondrop_cb: drop_cb

		# dragend: only fires at the *source* element. Would need to listen on document.
		# But is not fired at all with file drops so useless.

	el.addEventListener 'dragover', drag_data.ondragover, false
	el.addEventListener 'dragenter', drag_data.ondragenter, false
	el.addEventListener 'dragleave', drag_data.ondragleave, false
	el.addEventListener 'drop', drag_data.ondrop, false

	drag_data_by_el.set el, drag_data

disable_drop = (###* @type {HTMLElement} ### el) =>
	el.classList.remove 'drop-target'
	drag_data = drag_data_by_el.get el
	if not drag_data
		return
	el.removeEventListener 'dragover', drag_data.ondragover
	el.removeEventListener 'dragenter', drag_data.ondragenter
	el.removeEventListener 'dragleave', drag_data.ondragleave
	el.removeEventListener 'drop', drag_data.ondrop
	drag_data_by_el.delete el

#
###* @type {Vue.Directive} ###
directive =
	mounted: (el, { value }) ->
		if value
			set_drop el, value
	updated: (el, { value }) ->
		value = value or null
		if not value
			disable_drop el
		else
			set_drop el, value
	unmounted: (el) ->
		disable_drop el

export default directive
