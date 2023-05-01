<template lang="slm">
div
	h2 {{ commits.length }} COMMITS SELECTED

	p {{ commits.map(c=>c.hash).join(' ') }}

	.row.gap-5.wrap
		git-action-button v-for="action of commits_actions" :git_action="action"

	template v-if="commits.length===2"
		h3 Comparison of two commits
		ul.comparison
			li v-for="file of comparison_files"
				button.change.row.center.gap-5 @click="show_compare_diff(file.path)"
					/ TODO: sub component
					.count {{ (file.insertions + file.deletions) || 0 }}
					progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0" title="Ratio insertions / deletions"
					.path.flex-1 {{ file.path }}
</template>

<script lang="coffee" src="./CommitsDetails.coffee"></script>

<style lang="stylus" scoped>
h2.summary
	white-space pre-line
	word-break break-word
	overflow hidden
	text-overflow ellipsis
.changed-files, .comparison
	padding 0
	overflow auto
	.change
		font-family monospace
		> .count
			text-align right
			width 2rem
		> .path
			white-space pre
			// white-space pre-line
			// text-indent -1rem
			// padding-left 1rem
</style>