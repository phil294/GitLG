import Vue from 'vue'

/**
@type {Vue.DirectiveHook<HTMLElement>}
Make element movable. Does not have to be the directive el itself.
Side effect: This makes the element become position absolute permanently.
 */
function apply(target, { value: { move_target, onmovestart, onmoveend, snap_back } = {} }) {
	if (move_target === undefined)
		move_target = target
	else if (move_target === 'parent')
		move_target = target.parentElement
	else if (move_target === null)
		return

	target.draggable = true
	function start_move(/** @type {MouseEvent | TouchEvent} */ event) {
		event.preventDefault()

		let mouse_start_x = event.pageX || event.changedTouches[0].pageX
		let mouse_start_y = event.pageY || event.changedTouches[0].pageY

		let el_start_left = parseInt(move_target.style.left, 10) || 0
		let el_start_top = parseInt(move_target.style.top, 10) || 0

		move_target.style.width = move_target.offsetWidth + 'px'
		move_target.style.height = move_target.offsetHeight + 'px'
		move_target.style.left = el_start_left + 'px'
		move_target.style.top = el_start_top + 'px'
		move_target.style.position = 'relative'

		let offset_x = 0
		let offset_y = 0

		if (onmovestart)
			onmovestart()

		function on_mousemove(/** @type MouseEvent | TouchEvent */ mouse_event) {
			event.preventDefault()
			window.requestAnimationFrame(() => {
				offset_x = (mouse_event.pageX || mouse_event.changedTouches?.[0].pageX || 0) - mouse_start_x
				offset_y = (mouse_event.pageY || mouse_event.changedTouches?.[0].pageY || 0) - mouse_start_y
				move_target.style.left = el_start_left + offset_x + 'px'
				move_target.style.top = el_start_top + offset_y + 'px'
			})
		}

		document.addEventListener('mousemove', on_mousemove)
		document.addEventListener('touchmove', on_mousemove)

		function on_mouseup(/** @type MouseEvent | TouchEvent */ event) {
			event.preventDefault()
			document.removeEventListener('mousemove', on_mousemove)
			document.removeEventListener('touchmove', on_mousemove)
			document.removeEventListener('mouseup', on_mouseup)
			document.removeEventListener('touchend', on_mouseup)
			window.requestAnimationFrame(() => {
				if (snap_back) {
					move_target.style.height = ''
					move_target.style.width = ''
					move_target.style.top = ''
					move_target.style.left = ''
				}
				if (onmoveend)
					onmoveend({ offset: { x: offset_x, y: offset_y } })
			})
		}

		document.addEventListener('mouseup', on_mouseup)
		document.addEventListener('touchend', on_mouseup)

		target.ondragstart = () => false
	}

	target.onmousedown = start_move
	target.ontouchstart = start_move
}

export default apply
