import { is_branch } from './types'
import { defineComponent, computed } from 'vue'
import { head_branch, combine_branches, branch_actions, stash_actions, tag_actions, selected_git_action, show_branch } from './store.coffee'
###* @typedef {import('./types').GitRef} GitRef ###
###* @typedef {import('./types').Commit} Commit ###
###* @typedef {import('./types').GitAction} GitAction ###

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
		branch = computed =>
			if is_branch props.git_ref
				props.git_ref
			else
				null
		to_context_menu_entries = (###* @type GitAction[] ### actions) =>
			actions.map (action) =>
				label: action.title
				icon: action.icon
				action: =>
					selected_git_action.value = action

		bind: computed =>
			is_head = props.git_ref.id == head_branch.value
			style:
				color: props.git_ref.color
				border:
					if is_head
						"2px solid #{props.git_ref.color}"
					else undefined
			class:
				head: is_head
				branch: !! branch.value
				inferred: !! branch.value?.inferred
		drag: computed =>
			if branch.value then props.git_ref.id
		drop: (###* @type {import('../directives/drop').DropCallbackPayload} ### event) =>
			return if not branch.value
			source_branch_name = event.data
			return if typeof source_branch_name != 'string'
			combine_branches(source_branch_name, props.git_ref.id)
		context_menu_provider: computed => =>
			if branch.value
				to_context_menu_entries(branch_actions(branch.value).value)
					.concat
						label: 'Show'
						icon: 'eye'
						action: =>
							show_branch(branch.value or throw '?')
			else if props.git_ref.type == 'stash' and props.commit
				to_context_menu_entries(stash_actions(props.git_ref.name).value)
			else if props.git_ref.type == 'tag'
				to_context_menu_entries(tag_actions(props.git_ref.name).value)