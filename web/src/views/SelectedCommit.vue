<template lang="slm">
div
	h2.summary :title="commit.subject" {{ commit.subject }}

	p.body {{ body }}

	div v-if="stash"
		h3 Stash:
		.row.gap-5.wrap
			button.btn v-for="action of stash_actions" @click="popup_action = action"
				| {{ action.title }}
	
	div v-if="branch_tips.length"
		h3 Branches:
		ul.branches v-for="branch_tip of branch_tips"
			li
				h3 :style="{color:branch_tip.color}"
					| {{ branch_tip.name }}
				.row.gap-5.wrap
					button.btn v-for="action of branch_actions(branch_tip.name)" @click="popup_action = action" :title="action.description"
						| {{ action.title }}

	h3 This commit {{ commit.hash }}:
	.row.gap-5.wrap
		button.btn v-for="action of commit_actions" @click="popup_action = action"
			| {{ action.title }}
	
	h3 Changed files:
	ul.changed-files
		li v-for="file of changed_files"
			button.row.center.gap-5 @click="show_diff(file.path)"
				.change-count {{ file.insertions + file.deletions }}
				progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0" title="Ratio insertions / deletions"
				.flex-1 {{ file.path }}
	
	git-popup v-if="popup_action" :git_action="popup_action" @close="popup_action=null"
</template>

<script lang="coffee" src="./SelectedCommit.coffee"></script>

<style lang="stylus">
#selected-commit
	width 350px
	h2.summary
		white-space pre
		overflow hidden
		text-overflow ellipsis
.selected-input
	width: clamp(200px, 50vw, 50vw)
.changed-files
	padding 0
	white-space pre
	overflow auto
	.change-count
		font-family monospace
		text-align right
		width 2rem
.body
	white-space pre-wrap
	word-break break-word
</style>