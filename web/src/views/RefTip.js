import { is_branch } from './types'
import { defineComponent, computed } from 'vue'
import { head_branch, combine_branches, branch_actions, stash_actions, tag_actions, selected_git_action, show_branch } from './store.js'

export default defineComponent({
	props: {
		git_ref: {
			required: true,
			/** @type {() => GitRef} */
			type: Object,
		},
		commit: {
			/** @type {() => Commit} */
			type: Object,
		},
	},
	setup(props) {
		let branch = computed(() => {
			if (is_branch(props.git_ref))
				return props.git_ref
			else
				return null
		})
		function to_context_menu_entries(/** @type GitAction[] */ actions) {
			return actions.map((action) => ({
				label: action.title,
				icon: action.icon,
				action() {
					selected_git_action.value = action
				},
			}))
		}
		return {
			bind: computed(() => {
				let is_head = props.git_ref.id === head_branch.value
				return {
					style: {
						color: props.git_ref.color,
						border: is_head
							? `2px solid ${props.git_ref.color}`
							: undefined,
					},
					class: {
						head: is_head,
						branch: !! branch.value,
						inferred: !! branch.value?.inferred,
					},
				}
			}),
			drag: computed(() => {
				if (branch.value)
					return props.git_ref.id
			}),
			drop(/** @type {import('../directives/drop').DropCallbackPayload} */ event) {
				if (! branch.value)
					return
				let source_branch_name = event.data
				if (typeof source_branch_name !== 'string')
					return
				return combine_branches(source_branch_name, props.git_ref.id)
			},
			context_menu_provider: computed(() => () => {
				if (branch.value)
					return to_context_menu_entries(branch_actions(branch.value).value)
						.concat({
							label: 'Show',
							icon: 'eye',
							action() {
								show_branch(branch.value)
							},
						})
				else if (props.git_ref.type === 'stash' && props.commit)
					return to_context_menu_entries(stash_actions(props.git_ref.name).value)
				else if (props.git_ref.type === 'tag')
					return to_context_menu_entries(tag_actions(props.git_ref.name).value)
			}),
		}
	},
})
