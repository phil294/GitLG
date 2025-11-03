<template>
	<div :class="['commit-ref-tips', 'row', 'align-center', { 'flex-wrap': allow_wrap }]">
		<div v-for="ref of grouped_git_refs" :key="ref.id" class="ref-item" @click.stop>
			<ref-tip :commit="commit" :git_ref="ref" :show_buttons="show_buttons" />
		</div>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import config from '../data/store/config'

let props = defineProps({
	commit: {
		required: true,
		/** @type {Vue.PropType<Commit>} */
		type: Object,
	},
	refs: {
		required: false,
		/** @type {Vue.PropType<GitRef[]>} */
		type: Array,
		default: null,
	},
	allow_wrap: {
		type: Boolean,
		default: false,
	},
	show_buttons: {
		type: Boolean,
		default: false,
	},
	ref_title: {
		type: Function,
		default: null,
	},
})

function group_same_name_branches_into_one(/** @type {Branch[]} */ branches) {
	return {
		...not_null(branches[0]),
		remote_name: undefined,
		id: not_null(branches[0]).id,
		remote_names_group: branches
			.map(ref => ref.remote_name)
			.filter(is_truthy),
	}
}

let grouped_git_refs = computed(() => {
	const input_refs = props.refs || props.commit.refs
	if (config.get_boolean_or_undefined('group-branch-remotes') === false)
		return input_refs

	// Group refs by name
	const grouped_by_name = input_refs.reduce((/** @type {Record<string, GitRef[]>} */ all, ref) => {
		all[ref.name] = [...all[ref.name] || [], ref]
		return all
	}, {})

	return Object.values(grouped_by_name)
		.map(name_group => {
			let as_branches = name_group.filter(is_branch)
			let is_all_branches = as_branches.length === name_group.length
			let has_local_branch_tip = as_branches.some(branch => ! branch.remote_name)
			if (as_branches.length > 1 && is_all_branches && has_local_branch_tip)
				return group_same_name_branches_into_one(as_branches)
			return name_group
		}).flat()
})
</script>
<style scoped>
.commit-ref-tips {
	line-height: 1em;
	z-index: 1;
}
.commit-ref-tips.flex-wrap {
	flex-wrap: wrap;
}
.ref-item {
	display: flex;
	flex-direction: column;
	align-items: flex-start;
}
</style>
