<template lang="slm">
.commits-details
	h2.count {{ commits.length }} COMMITS SELECTED

	p.hashes {{ commits.map(c=>c.hash).join(' ') }}

	.row.gap-5.wrap
		git-action-button v-for="action of commits_actions" :git_action="action"

	template v-if="commits.length===2"
		h3 Comparison of two commits
		files-diffs-list :files="comparison_files" @show_diff="show_compare_diff" @view_rev="view_rev"
</template>

<script lang="coffee" src="./CommitsDetails.coffee"></script>

<style lang="stylus" scoped>
h2.summary
	white-space pre-line
	word-break break-word
	overflow hidden
	text-overflow ellipsis
</style>