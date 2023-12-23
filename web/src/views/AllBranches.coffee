import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { branches } from './store.coffee'
import RefTip from './RefTip.vue'

export default
	emit: ['branch_selected']
	components: { RefTip }
	setup: (props, { emit }) ->
		details_ref = ref null
		txt_filter = ref ''
		filtered_branches = computed =>
			if not txt_filter.value
				branches.value
			else
				branches.value.filter (branch) =>
					branch.id.toLowerCase().includes(txt_filter.value.toLowerCase())
		on_mouse_up = (###* @type MouseEvent ### event) =>
			if not (event.target instanceof Element) or
					event.target.parentElement?.getAttribute('id') != 'show-all-branches' and
					not event.target.classList.contains('ref-tip') and
					not event.target.classList.contains('filter') and
					not event.target.querySelector('.ref-tip') and
					not event.target.parentElement?.classList.contains('context-menu-wrapper')
				# @ts-ignore TODO: .
				details_ref.value?.removeAttribute 'open'
		onMounted =>
			document.addEventListener 'mouseup', on_mouse_up
		onUnmounted =>
			document.removeEventListener 'mouseup', on_mouse_up
		go_to_head = () =>
			emit 'branch_selected', 'HEAD'
		{
			filtered_branches
			txt_filter
			go_to_head
			details_ref
		}