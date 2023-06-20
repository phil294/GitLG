<template lang="slm">
.selected-git-action
	h2
		template v-if="selected_git_action.title"
			| {{ selected_git_action.title }} -&nbsp;
		| {{ selected_git_action.description }}
	details.padding v-if="selected_git_action.info"
		summary {{ selected_git_action.info }}
		| {{ selected_git_action.info }}
	git-input :git_action="selected_git_action" @success="success()" @executed="executed()"
	br
	label.row.align-center.gap-5
		input type="checkbox" v-model="keep_open"
		| Keep window open after success
</template>

<script lang="coffee" src="./SelectedGitAction.coffee"></script>

<style lang="stylus">
.selected-git-action
	width: clamp(200px, 50vw, 50vw)
	> details
		white-space pre-line
		> summary
			overflow hidden
			text-overflow ellipsis
			color grey
</style>