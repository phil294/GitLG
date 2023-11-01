<template lang="slm">
.commits-details
	h2.count {{ commits.length }} COMMITS SELECTED

	p.hashes {{ commits.map(c=>c.full_hash).join(' ') }}

	.row.gap-5.wrap
		git-action-button v-for="action of commits_actions" :git_action="action"

	template v-if="commits.length===2"
		h3 Comparison of two commits
		files-diffs-list :files="comparison_files" @show_diff="show_compare_diff" @view_rev="view_rev"
		h3 Merge bases
		ul
			li v-for="merge_base of merge_bases"
				| {{ merge_base }}
				button @click="$emit('hash_clicked',merge_base)" title="Jump to commit"
					i.codicon.codicon-link
</template>

<script lang="coffee" src="./CommitsDetails.coffee"></script>

<style lang="stylus" scoped>
h2.summary
	white-space pre-line
	word-break break-word
	overflow hidden
	text-overflow ellipsis
</style>