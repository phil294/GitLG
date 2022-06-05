<template lang="slm">
div
	button.btn @click="show_popup=true" :title="git_action.description"
		| {{ git_action.title }}
	popup v-if="show_popup" @close="show_popup=false"
		.selected-input
			p Execute Git command
			git-input :git_action="git_action" @success="success()"
			label.row.align-center.gap-5
				input type="checkbox" v-model="keep_open"
				| Keep window open after success
</template>

<script lang="coffee" src="./GitActionButton.coffee"></script>

<style lang="stylus">
.selected-input
	width: clamp(200px, 50vw, 50vw)
</style>