<template lang="slm">
#all-branches
	details#show-all-branches.center ref="details_ref"
		summary
			| All branches...
		div.dv
			input.filter v-model="txt_filter" placeholder="🔍 filter branch name"
			.branches
				button v-for="branch of filtered_branches" @click="$emit('branch_selected',branch);show_all_branches=false" title="Jump to branch tip"
					ref-tip :git_ref="branch"
</template>

<script lang="coffee" src="./AllBranches.coffee"></script>

<style lang="stylus" scoped>
details#show-all-branches
	> summary
		display flex
		align-items center
		justify-content end
.dv
	padding 5px 10px 20px 20px
	> button > .ref-tip.branch
		margin 2px
		padding 1px 6px
input.filter
	margin 5px
	float right
	width unset !important
</style>