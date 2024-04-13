<template lang="slm">
.ref-tip v-bind="bind" v-drag="drag" v-drop="drop" v-context-menu="context_menu_provider"
	| {{ git_ref.id }}
</template>

<script lang="coffee" src="./RefTip.coffee"></script>

<style lang="stylus" scoped>
.ref-tip
	background: #373737;
	font-weight: normal;
	display: inline-block;
	padding: 0px 4px 1px;
	border: 1px solid #424141;
	border-radius: 4px;
	white-space: pre;
	margin-right: 3px;
	font-size: 11px;
	&.head
		//box-shadow 0px 0px 6px 4px #ffffff30, 0px 0px 4px 0px #ffffff30 inset
		&:after
			content ' (HEAD)'
			color white
	&.branch
		cursor move
		&.inferred
			background #00000091
			opacity 0.7
			font-weight normal
			&:hover
				opacity unset
				font-weight bold
				background black
		&.dragenter
			background white !important
			color red !important
</style>