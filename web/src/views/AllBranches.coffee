import { ref, computed } from 'vue'
import { branches } from './store.coffee'
import RefTip from './RefTip.vue'

export default
	emit: ['branch_drop', 'branch_selected']
	components: { RefTip }
	setup: ->
		show_all_branches = ref false
		txt_filter = ref ''
		filtered_branches = computed =>
			if not txt_filter.value
				branches.value
			else
				branches.value.filter (branch) =>
					branch.name.toLowerCase().includes(txt_filter.value.toLowerCase())
		{
			show_all_branches
			filtered_branches
			txt_filter
		}