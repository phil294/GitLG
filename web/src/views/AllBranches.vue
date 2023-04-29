<template lang="slm">
#all-branches
	button.btn#show-all-branches @click="show_all_branches = ! show_all_branches"
		| All branches
	div v-if="show_all_branches"
		.background @click="show_all_branches=false"
		input.filter v-model="txt_filter" placeholder="🔍 filter branch name"
		.branches
			.ref.branch-tip v-for="branch of filtered_branches" :class="{is_head:branch.name===head_branch}" v-drag="branch.name" v-drop="(e)=>$emit('branch_drop',[branch.name,e])"
				button :style="{color:branch.color}" @click="$emit('scroll_to_branch_tip',branch.name);show_all_branches=false" title="Jump to branch tip"
					| {{ branch.name }}
</template>

<script lang="coffee" src="./AllBranches.coffee"></script>

<style lang="stylus" scoped>
.background
	position fixed
	inset 0
	z-index -1
#show-all-branches
	float right
.branches
	> .branch-tip
		margin 2px
		padding 1px 6px
input.filter
	margin 5px
	float right
	width unset !important
</style>