<template lang="slm">
div
	h2 {{ commits.length }} COMMITS SELECTED

	p {{ commits.map(c=>c.hash).join(' ') }}

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