<template>
	<div class="commits-details">
		<h2 class="count">
			<!-- TODO: styling -->
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

			<!-- TODO: [0] should yield unsafe array access type error..?? -->
			<commit-diff :commit1="commits[0]" :commit2="commits[1]" />
		</template>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { commits_actions as commits_actions_ } from '../../data/store/actions'

let props = defineProps({
	commits: {
		/** @type {Vue.PropType<Commit[]>} */
		type: Array,
		required: true,
	},
})

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
