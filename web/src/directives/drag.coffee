import Vue from 'vue'

/** @type {Vue.DirectiveHook<HTMLElement>} */
function updated(el, { value }) {
	el.setAttribute('draggable', !! value)
	if (value)
		el.dataset.drag_value = JSON.stringify(value)
}

/** @type {Vue.Directive<HTMLElement>} */
let directive = {
	mounted(el, binding) {
		el.addEventListener('dragstart', (e) => {
			if (e.dataTransfer) {
				e.dataTransfer.setData('application/json', el.dataset.drag_value)
				e.dataTransfer.dropEffect = 'move'
			}
		})
		return updated(el, binding)
	},
	updated,
}

export default directive
