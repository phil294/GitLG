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
			<files-diffs-list :files="comparison_files" @show_diff="show_compare_diff" @view_rev="view_rev" />
		</template>
	</div>
</template>
<script src="./CommitsDetails"></script>
<style scoped>
h2.summary {
	white-space: pre-line;
	word-break: break-word;
	overflow: hidden;
	text-overflow: ellipsis;
}
</style>
