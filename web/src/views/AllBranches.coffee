import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { branches } from './store.coffee'
import RefTip from './RefTip.vue'

export default
	emit: ['branch_selected']
	components: { RefTip }
	setup: ->
		show_all_branches = ref false
		txt_filter = ref ''
		filtered_branches = computed =>
			if not txt_filter.value
				branches.value
			else
				branches.value.filter (branch) =>
					branch.id.toLowerCase().includes(txt_filter.value.toLowerCase())
		on_mouse_up = (###* @type MouseEvent ### event) =>
			await nextTick()
			if not (event.target instanceof Element) or
					event.target.getAttribute('id') != 'show-all-branches' and
					not event.target.classList.contains('ref-tip') and
					not event.target.classList.contains('filter') and
					not event.target.querySelector('.ref-tip') and
					not event.target.parentElement?.classList.contains('context-menu-wrapper')
				show_all_branches.value = false
		onMounted =>
			document.addEventListener 'mouseup', on_mouse_up
		onUnmounted =>
			document.removeEventListener 'mouseup', on_mouse_up
		{
			show_all_branches
			filtered_branches
			txt_filter
		}