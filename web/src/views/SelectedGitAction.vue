<template lang="slm">
.selected-git-action
	p Execute Git command
	git-input :git_action="selected_git_action" @success="success()" @executed="executed()"
	label.row.align-center.gap-5
		input type="checkbox" v-model="keep_open"
		| Keep window open after success
</template>

<script lang="coffee" src="./SelectedGitAction.coffee"></script>

<style lang="stylus">
.selected-git-action
	width: clamp(200px, 50vw, 50vw)
</style>
