<template lang="slm">
div
	h2.summary :title="commit.subject" {{ commit.subject }}

	p.body {{ body }}

	div v-if="stash"
		h3 Stash:
		.row.gap-5.wrap
			git-action-button v-for="action of stash_actions" :git_action="action" @change="$emit('change')"

	div v-if="branch_tips.length"
		h3 Branches:
		ul.branches v-for="branch_tip of branch_tips"
			li
				h3 :style="{color:branch_tip.color}"
					| {{ branch_tip.name }}
				.row.gap-5.wrap
					git-action-button v-for="action of branch_actions(branch_tip.name)" :git_action="action" @change="$emit('change')"

	h3 This commit {{ commit.hash }}:
	.row.gap-5.wrap
		git-action-button v-for="action of commit_actions" :git_action="action" @change="$emit('change')"

	h3 Changed files:
	ul.changed-files
		li v-for="file of changed_files"
			button.change.row.center.gap-5 @click="show_diff(file.path)"
				.count {{ (file.insertions + file.deletions) || 0 }}
				progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0" title="Ratio insertions / deletions"
				.path.flex-1 {{ file.path }}
</template>

<script lang="coffee" src="./SelectedCommit.coffee"></script>

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
</style>