<template lang="slm">
.ref-tip v-bind="bind" v-drag="drag" v-drop="drop" v-context-menu="context_menu_provider"
	| {{ git_ref.id }}
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
	&.head
		border 3px solid white
		box-shadow 0px 0px 6px 4px #ffffff30, 0px 0px 4px 0px #ffffff30 inset
		&:after
			content ' (HEAD)'
			color white
	&.branch
		cursor move
		&.dragenter
			background white !important
			color red !important
</style>
