<template lang="slm">
popup @close="close()"
	.selected-input
		p Execute Git command
		git-input v-bind="$attrs" @success="success()"
		label.row.align-center.gap-5
			input type="checkbox" v-model="keep_open"
			| Keep window open after success
</template>

<script lang="coffee" src="./GitPopup.coffee"></script>

<style lang="stylus">
.selected-input
	width: clamp(200px, 50vw, 50vw)
</style>