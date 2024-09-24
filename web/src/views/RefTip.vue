<template>
	<div v-context-menu="context_menu_provider" v-drag="drag" v-drop="drop" class="ref-tip" v-bind="bind">
		{{ git_ref.id }}
	</div>
</template>
<script>
import { defineComponent, computed } from 'vue'
import { head_branch, combine_branches, branch_actions, stash_actions, tag_actions, selected_git_action, show_branch } from '../state/store.js'

export default defineComponent({
	props: {
		git_ref: {
			/** @type {Vue.PropType<GitRef>} */
			type: Object,
			required: true,
		},
		commit: {
			/** @type {Vue.PropType<Commit>} */
			type: Object,
			default: null,
		},
	},
	setup(props) {
		let branch = computed(() => {
			if (is_branch(props.git_ref))
				return props.git_ref
			else
				return null
		})
		function to_context_menu_entries(/** @type {GitAction[]} */ actions) {
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
								if (branch.value)
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
</script>
<style scoped>
.ref-tip {
	background: #000;
	font-weight: bold;
	font-style: italic;
	display: inline-block;
	padding: 1px 3px;
	border: 1px solid #505050;
	border-radius: 7px;
	white-space: pre;
	margin: 0 1px;
}
.ref-tip.head {
	box-shadow: 0px 0px 6px 4px rgba(255,255,255,0.188), 0px 0px 4px 0px rgba(255,255,255,0.188) inset;
}
.ref-tip.head:after {
	content: ' (HEAD)';
	color: #fff;
}
.ref-tip.branch {
	cursor: move;
}
.ref-tip.branch.inferred {
	background: rgba(0,0,0,0.569);
	opacity: 0.7;
	font-weight: normal;
}
.ref-tip.branch.inferred:hover {
	opacity: unset;
	font-weight: bold;
	background: #000;
}
.ref-tip.branch.dragenter {
	background: #fff !important;
	color: #f00 !important;
}
</style>
