<template lang="slm">
div
	h2.summary :title="commit.subject" {{ commit.subject }}

	p.body {{ body }}
	
	div v-if="branch_tips.length"
		h3 Branches:
		ul.branches v-for="branch_tip of branch_tips"
			li
				h3 :style="{color:branch_tip.color}"
					| {{ branch_tip.name }}
				.row.gap-5.wrap
					button.btn v-for="action of branch_actions(branch_tip.name)" @click="args = {...action, config_key: 'branch-'+action.title}"
						| {{ action.title }}

	h3 This commit {{ commit.hash }}:
	.row.gap-5.wrap
		button.btn v-for="action of commit_actions" @click="args = {...action, config_key: 'commit-'+action.title}"
			| {{ action.title }}
	
	h3 Changed files:
	ul.changed-files
		li v-for="file of changed_files"
			button.row.center.gap-5 @click="show_diff(file.path)"
				.change-count {{ file.insertions + file.deletions }}
				progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0" title="Ratio insertions / deletions"
				.flex-1 {{ file.path }}
	
	popup v-if="args" @close="args=null"
		.selected-input
			p Execute Git command
			git-input v-bind="args" @success="git_execute_success()"
			label.row.align-center.gap-5
				input type="checkbox" v-model="keep_open"
				| Keep window open after success
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
</style>