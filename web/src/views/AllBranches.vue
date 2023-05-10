<template lang="slm">
#all-branches
	button.btn#show-all-branches @click="show_all_branches = ! show_all_branches"
		| All branches
	div v-show="show_all_branches"
		input.filter v-model="txt_filter" placeholder="🔍 filter branch name"
		.branches
			button v-for="branch of filtered_branches" @click="$emit('branch_selected',branch.id);show_all_branches=false" title="Jump to branch tip"
				ref-tip :git_ref="branch"
</template>

<script lang="coffee" src="./AllBranches.coffee"></script>

<style lang="stylus" scoped>
#show-all-branches
	float right
.branches
	> button > .ref-tip.branch
		margin 2px
		padding 1px 6px
input.filter
	margin 5px
	float right
	width unset !important
</style>