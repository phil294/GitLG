/** @param el {HTMLElement} @param arg {{value: any}} */
function updated(el, { value }) {
	if (value)
		el.setAttribute('draggable', 'true')
	else
		el.removeAttribute('draggable')
	if (value)
		el.dataset.drag_value = JSON.stringify(value)
}

/** @type {Vue.Directive<HTMLElement>} */
let directive = {
	mounted(el, binding) {
		el.addEventListener('dragstart', (e) => {
			if (e.dataTransfer && el.dataset.drag_value) {
				e.dataTransfer.setData('application/json', el.dataset.drag_value)
				e.dataTransfer.dropEffect = 'move'
			}
		})
		updated(el, binding)
	},
	updated,
}

export default directive
