<template lang="slm">
.ref-tip v-bind="bind" v-drag="drag" v-drop="drop"
	| {{ git_ref.name }}
</template>

<script lang="coffee" src="./RefTip.coffee"></script>

<style lang="stylus" scoped>
.ref-tip
	background black
	font-weight bold
	font-style italic
	display inline-block
	padding 1px 3px
	border 1px solid #505050
	border-radius 7px
	white-space pre
	margin 0 1px
	&.head:after
		content ' (HEAD)'
		color white
	&.branch
		&.dragenter
			background white !important
			color red !important
</style>