import { defineComponent, computed } from 'vue'
import { head_branch, combine_branches } from './store.coffee'
``###* @typedef {import('./types').GitRef} GitRef ###

export default defineComponent
	props:
		git_ref:
			required: true
			###* @type {() => GitRef} ###
			type: Object
	setup: (props) ->
		is_branch = computed =>
			props.git_ref.type == 'branch'
		bind: computed =>
			style:
				color: props.git_ref.color
			class:
				'head': props.git_ref.name == head_branch.value
				'branch': is_branch.value
		drag: computed =>
			if is_branch.value then props.git_ref.name
		drop: (###* @type {import('../directives/drop').DropCallbackPayload} ### event) =>
			return if not is_branch.value
			source_branch_name = event.data
			return if typeof source_branch_name != 'string'
			combine_branches(source_branch_name, props.git_ref.name)