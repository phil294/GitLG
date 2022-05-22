<template lang="slm">
div
	h2.summary {{ commit.subject }}
	
	div v-if="branch_tips.length"
		h3 Branches:
		ul.branches v-for="branch_tip of branch_tips"
			li
				h3 :style="{color:branch_tip.color}"
					| {{ branch_tip.name }}
				.row.gap-5.wrap
					button.btn @click="do_git('checkout '+branch_tip.name)"
						| →&nbsp;&nbsp;&nbsp;Checkout
					button.btn @click="args = { args: 'merge '+branch_tip.name, options: [ { name: '--no-commit', default: false } ] }"
						| ⛙&nbsp;&nbsp;&nbsp;Merge
					button.btn @click="args = { args: 'branch -m '+branch_tip.name+' NEW_NAME_HERE' }"
						| ✎&nbsp;&nbsp;&nbsp;Rename
					button.btn @click="args = { args: 'branch -d '+branch_tip.name, options: [ { name: '--force', default: false } ] }"
						| 🗑&nbsp;&nbsp;&nbsp;Delete

	h3 This commit:
	.row.gap-5.wrap
		button.btn @click="do_git('checkout '+commit.hash)"
			| →&nbsp;&nbsp;&nbsp;Checkout
		button.btn @click="args = { args: 'branch NEW_BRANCH_NAME '+commit.hash }"
			| +&nbsp;&nbsp;&nbsp;Create branch
		button.btn @click="args = { args: 'cherry-pick '+commit.hash, options: [ { name: '--no-commit', default: false } ] }"
			| 𖣣&nbsp;&nbsp;&nbsp;Cherry pick
		button.btn @click="args = { args: 'revert '+commit.hash, options: [ { name: '--no-commit', default: false } ] }"
			| ⎌&nbsp;&nbsp;&nbsp;Revert
	
	popup v-if="args" @close="args=null"
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
.popup
	width: clamp(200px, 50vw, 50vw)
</style>