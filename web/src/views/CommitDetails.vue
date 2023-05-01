<template lang="slm">
div
	h2.summary :title="commit.subject" {{ commit.subject }}

	p.body {{ body }}

	div v-if="stash"
		h3 Stash:
		.row.gap-5.wrap
			git-action-button v-for="action of stash_actions" :git_action="action"

	div v-if="branch_tips.length"
		ul.branches v-for="branch_tip of branch_tips"
			li
				ref-tip :git_ref="branch_tip" :commit="commit"
				.row.gap-5.wrap
					git-action-button v-for="action of branch_actions(branch_tip.name)" :git_action="action"
	
	div v-if="tags.length"
		ul.tags v-for="tag, tag_i of tags"
			li
				ref-tip :git_ref="tag" :commit="commit"
				pre {{ tag_details[tag_i] }}
				.row.gap-5.wrap
					git-action-button v-for="action of tag_actions(tag.name)" :git_action="action"

	h3
		| This commit 
		button @click="$emit('hash_clicked',commit.hash)"
			| {{ commit.hash }}
		| :
	.row.gap-5.wrap
		git-action-button v-for="action of commit_actions" :git_action="action"

	h3 Changed files:
	ul.changed-files
		li v-for="file of changed_files"
			button.change.row.center.gap-5 @click="show_diff(file.path)"
				.count {{ (file.insertions + file.deletions) || 0 }}
				progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0" title="Ratio insertions / deletions"
				.path.flex-1 {{ file.path }}
</template>

<script lang="coffee" src="./CommitDetails.coffee"></script>

<style lang="stylus" scoped>
h2.summary
	white-space pre-line
	word-break break-word
	overflow hidden
	text-overflow ellipsis
.selected-input
	width: clamp(200px, 50vw, 50vw)
.changed-files
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
.body
	white-space pre-wrap
	word-break break-word
.branches, .tags
	.ref-tip
		margin 20px 10px 10px
</style>