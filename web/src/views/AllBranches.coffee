import { ref, Ref, ComputedRef, computed, watch, nextTick } from 'vue'

export default
	emit: ['branch_drop', 'scroll_to_branch_tip']
	props:
		branches:
			type: Array
			required: true
		head_branch:
			required: true
			type: String
	setup: (props) ->
		show_all_branches = ref false
		txt_filter = ref ''
		filtered_branches = computed =>
			if not txt_filter.value
				props.branches
			else
				props.branches.filter (branch) =>
					branch.name.toLowerCase().includes(txt_filter.value.toLowerCase())
		{
			show_all_branches
			filtered_branches
			txt_filter
		}