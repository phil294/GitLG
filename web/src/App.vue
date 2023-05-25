<template lang="slm">
#vue-app
	main-view
</template>

<script lang="coffee">
import MainView from './views/MainView.vue'
import * as store from './views/store.coffee'

export default
	components: { MainView }
	setup: ->
		store.init()
		undefined
</script>

<style lang="stylus">
:root {
	--container-padding: 20px;
	--input-padding-vertical: 6px;
	--input-padding-horizontal: 4px;
	--input-margin-vertical: 4px;
	--input-margin-horizontal: 0;
}

body {
	color: #cccccc;
	font-size: var(--vscode-font-size);
	font-weight: var(--vscode-font-weight);
	font-family: var(--vscode-font-family);
	background-color: #161616;

	&.vscode-light, &.vscode-high-contrast-light {
		background-color: var(--vscode-editor-background);
		filter: invert(1) hue-rotate(180deg);
	}
}

ol, ul, *[role=list] {
	list-style none
	margin 0
	padding 0
}

*:focus {
	outline-color: var(--vscode-focusBorder) !important;
}

a {
	color: var(--vscode-textLink-foreground);
}

a:hover, a:active {
	color: var(--vscode-textLink-activeForeground);
}

code {
	font-family: var(--vscode-editor-font-family);
	color: #cccccc;
}

details
	cursor pointer

input:not([type='checkbox']):not([type='radio']), textarea {
	display: block;
	border: none;
	// font-family: var(--vscode-font-family);
	font-family: monospace;
	font-size 11.5px
	padding: var(--input-padding-vertical) var(--input-padding-horizontal);
	color: var(--vscode-input-foreground);
	outline-color: var(--vscode-input-border);
	background-color: var(--vscode-input-background);
}

input::placeholder,
textarea::placeholder {
	color: var(--vscode-input-placeholderForeground);
}

select
	color #cccccc
	background #161616
	border-color #333

body, html
	margin 0
	padding 0


*
	box-sizing border-box
.flex
	display flex
	min-height 0
	min-width 0
.flex-1
	flex 1
.flex-noshrink
	flex-shrink 0
.wrap
	flex-wrap wrap
.col
	@extend .flex
	flex-direction column
.row
	@extend .flex
	flex-direction row
.justify-center
	@extend .flex
	justify-content safe center
.align-center
	@extend .flex
	align-items safe center
.center
	@extend .justify-center, .align-center
.justify-flex-end
	justify-content flex-end
.justify-space-between
	justify-content space-between
.fill-w
	width 100%
.fill-h
	height 100%
.fill
	@extend .fill-w, .fill-h
.gap-3
	gap 3px
.gap-5
	gap 5px
.gap-10
	gap 10px
.col-gap-10
	column-gap 10px
.gap-20
	gap 20px
.padding
	padding: 0.5vmax
.padding-l
	padding: 1vh 1vw
.padding-xl
	padding: 3vmax
.error
	color darkred
.warn
	color orange
.grey
	color grey
button
	appearance none
	background initial
	border initial
	padding initial
	text-align initial
	font inherit
	color inherit // FF bug
	user-select none
	cursor pointer
	color #E5B567 // var(--vscode-gitDecoration-modifiedResourceForeground)
.btn, input[type="submit"], input[type="reset"], input[type="button"]
	display inline-flex
	align-items center
	white-space pre
	height 24px
	line-height 24px
	padding 3px 5px
	text-decoration none
	color var(--vscode-button-foreground)
	background var(--vscode-button-background)
	border 1px solid var(--vscode-button-background)
	// box-shadow 1px 1px 2px 1px #bbb
	&:enabled
		&:hover
			background var(--vscode-button-hoverBackground)
			border-color var(--vscode-button-hoverBackground)
			outline 0
		&:active
			opacity 0.7
			border-width 3px 0 0 2px
	&:disabled
		// background-color var(--color-disabled)
		// border-color grey
		color grey
		pointer-events auto // allow title popup
.btn.btn-2
	color var(--vscode-button-secondaryForeground)
	background var(--vscode-button-secondaryBackground)
.btn.btn-2:hover
	background var(--vscode-button-secondaryHoverBackground)

progress.diff
	width 30px
	height 3px

	// somehow both definitions are necessary?
	color #009900
	background-color darkred
	&::-webkit-progress-bar
		background-color darkred
	&::-webkit-progress-value
		background-color #009900

details > summary
	white-space nowrap

input:not([type='checkbox']):not([type='radio']).filter
	font-family monospace
	padding 0 0 0 5px
	background black
	color #d5983d

ul.context-menu-wrapper
	position absolute
	background #111111dd
	min-width 150px
	cursor pointer
	box-shadow 0 2px 3px 2px #111111dd
	user-select none
	z-index 10
	> li
		padding 4px 8px
		&:not(:last-child)
			border-bottom 1px solid #424242
		&:hover
			background black
</style>

<style lang="stylus" scoped>
#vue-app
	height 100vh
	width 100vw
.error
	background lightyellow
</style>
