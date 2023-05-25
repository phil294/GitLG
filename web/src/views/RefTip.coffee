import { defineComponent, computed } from 'vue'
import { head_branch, combine_branches, branch_actions, stash_actions, tag_actions, selected_git_action } from './store.coffee'
``###* @typedef {import('./types').GitRef} GitRef ###
``###* @typedef {import('./types').Commit} Commit ###
``###* @typedef {import('./types').GitAction} GitAction ###

export default defineComponent
	props:
		git_ref:
			required: true
			###* @type {() => GitRef} ###
			type: Object
		commit:
			###* @type {() => Commit} ###
			type: Object
	setup: (props) ->
		is_branch = computed =>
			props.git_ref.type == 'branch'
		to_context_menu_entries = (###* @type GitAction[] ### actions) =>
			actions.map (action) =>
				label: action.title
				icon: action.icon
				action: =>
					selected_git_action.value = action

		bind: computed =>
			style:
				color: props.git_ref.color
			class:
				'head': props.git_ref.id == head_branch.value
				'branch': is_branch.value
		drag: computed =>
			if is_branch.value then props.git_ref.id
		drop: (###* @type {import('../directives/drop').DropCallbackPayload} ### event) =>
			return if not is_branch.value
			source_branch_name = event.data
			return if typeof source_branch_name != 'string'
			combine_branches(source_branch_name, props.git_ref.id)
		context_menu_provider: computed => =>
			if is_branch.value
				to_context_menu_entries(branch_actions(props.git_ref).value)
			else if props.git_ref.type == 'stash' and props.commit
				to_context_menu_entries(stash_actions(props.git_ref.name).value)
			else if props.git_ref.type == 'tag'
				to_context_menu_entries(tag_actions(props.git_ref.name).value)
