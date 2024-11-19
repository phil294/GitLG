<template>
	<div class="commit-ref-tips row align-center">
		<ref-tip v-for="ref of grouped_git_refs" :key="ref.id" :commit="commit" :git_ref="ref" />
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { config } from '../state/store'

let props = defineProps({
	commit: {
		required: true,
		/** @type {Vue.PropType<Commit>} */
		type: Object,
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
	if (config.value['group-branch-remotes'] === false)
		return props.commit.refs
	return Object.values(props.commit.refs.reduce((/** @type {Record<string, GitRef[]>} */ all, ref) => {
		all[ref.name] = [...all[ref.name] || [], ref]
		return all
	}, {}))
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
</style>
