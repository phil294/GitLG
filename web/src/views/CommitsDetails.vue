<template>
	<div class="commits-details">
		<h2 class="count">
			{{ commits.length }} COMMITS SELECTED
		</h2>
		<p class="hashes">
			{{ commits.map(c=>c.hash).join(' ') }}
		</p>
		<div class="row gap-5 wrap">
			<git-action-button v-for="action, i of commits_actions" :key="i" :git_action="action" />
		</div>
		<template v-if="commits.length===2">
			<h3>
				Comparison of two commits
			</h3>

			<commit-file-changes v-if="comparison_files" :files="comparison_files" @show_diff="show_compare_diff" @show_multi_diff="show_multi_compare_diff" @view_rev="view_rev" />
			<div v-else class="loading padding">
				Loading files...
			</div>
		</template>
	</div>
</template>
<script setup>
import { ref, computed, watchEffect } from 'vue'
import { git, exchange_message } from '../bridge.js'
import { commits_actions as commits_actions_ } from '../data/store'
import { git_numstat_summary_to_changes_array } from './CommitDetails.vue'
/** @import { FileDiff } from './CommitFileChanges.vue' */

let props = defineProps({
	commits: {
		/** @type {Vue.PropType<Commit[]>} */
		type: Array,
		required: true,
	},
})

/** @type {Vue.Ref<FileDiff[] | null>} */
let comparison_files = ref(null)
watchEffect(async () => {
	if (props.commits.length !== 2)
		return
	comparison_files.value = null
	let get_files_command = `-c core.quotepath=false diff --numstat --summary --format="" ${not_null(props.commits[0]).hash} ${not_null(props.commits[1]).hash}`
	comparison_files.value = git_numstat_summary_to_changes_array(await git(get_files_command))
})

function show_compare_diff(/** @type {string} */ filepath) {
	exchange_message('open-diff', {
		hashes: [not_null(props.commits[0]).hash, not_null(props.commits[1]).hash],
		filename: filepath,
	})
}
function show_multi_compare_diff() {
	return exchange_message('open-multi-diff', {
		hashes: [not_null(props.commits[0]).hash, not_null(props.commits[1]).hash],
		filenames: (comparison_files.value || []).map(f => f.path),
	})
}
function view_rev(/** @type {string} */ filepath) {
	exchange_message('view-rev', {
		// TODO: ?
		hash: props.commits[1]?.hash,
		filename: filepath,
	})
}
let commits_actions = computed(() => commits_actions_(props.commits.map((c) => c.hash)).value)
</script>
<style scoped>
h2.summary {
	white-space: pre-line;
	word-break: break-word;
	overflow: hidden;
	text-overflow: ellipsis;
	margin-top: 0;
}
</style>
