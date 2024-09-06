/**
 * @type {Vue.DirectiveHook<HTMLElement, null, { move_target?: HTMLElement | 'parent' | null, onmovestart?: () => any, onmoveend?: (move_result: { offset: { x: number, y: number } }) => any, snap_back?: boolean }>}
 * Make element movable. Does not have to be the directive el itself.
 * Side effect: This makes the element become position absolute permanently.
 */
function apply(target, { value: { move_target: given_move_target = undefined, onmovestart = undefined, onmoveend = undefined, snap_back = false } = {} }) {
	let move_target = target
	if (given_move_target === null)
		return
	if (given_move_target === 'parent' && target.parentElement)
		move_target = target.parentElement

	target.draggable = true
	function start_move(/** @type {MouseEvent | TouchEvent} */ move_event) {
		move_event.preventDefault()

		let mouse_start_x = /** @type {MouseEvent} */(move_event).pageX || /** @type {TouchEvent} */(move_event).changedTouches[0].pageX // eslint-disable-line no-extra-parens
		let mouse_start_y = /** @type {MouseEvent} */(move_event).pageY || /** @type {TouchEvent} */(move_event).changedTouches[0].pageY // eslint-disable-line no-extra-parens

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

		function on_mousemove(/** @type {MouseEvent | TouchEvent} */ mouse_event) {
			move_event.preventDefault()
			window.requestAnimationFrame(() => {
				offset_x = (/** @type {MouseEvent} */(mouse_event).pageX || /** @type {TouchEvent} */(mouse_event).changedTouches?.[0].pageX || 0) - mouse_start_x // eslint-disable-line no-extra-parens
				offset_y = (/** @type {MouseEvent} */(mouse_event).pageY || /** @type {TouchEvent} */(mouse_event).changedTouches?.[0].pageY || 0) - mouse_start_y // eslint-disable-line no-extra-parens
				move_target.style.left = el_start_left + offset_x + 'px'
				move_target.style.top = el_start_top + offset_y + 'px'
			})
		}

		document.addEventListener('mousemove', on_mousemove)
		document.addEventListener('touchmove', on_mousemove)

		function on_mouseup(/** @type {MouseEvent | TouchEvent} */ mouseup_event) {
			mouseup_event.preventDefault()
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
