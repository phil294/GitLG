<template lang="slm">
.modal.popup
	Teleport to="body"
		.modal-body.center.fade-in @keydown.esc="close" :tabindex="-1" :bind="$attrs"
			.modal-background.fill @click="close"
			.modal-main.col ref="main_ref"
				header
					div.titlebar.center v-moveable="{move_target}"
						| ⠿⠿⠿⠿⠿
					button.close @click="close" type="button"
						i.codicon.codicon-close
				.popup-content
					slot
</template>

<script lang="coffee">
import { ref, onMounted } from 'vue'

export default
	inheritAttrs: false
	emits: [ 'close' ]
	setup: (props, { emit }) ->
		move_target = ref null
		main_ref = ref null
		onMounted =>
			move_target.value = main_ref.value
			main_ref.value.focus()

		{
			move_target
			main_ref
			close: =>
				emit 'close'
		}
</script>

<style lang="stylus" scoped>
.modal-body
	position fixed
	top 0
	left 0
	bottom 0
	right 0
	z-index 9999
	box-sizing border-box
.modal-background
	position absolute
	background rgba(0,0,0,0.6)
.modal-main
	max-height 98vh
	max-width 98vw
	min-width 50px
	position relative
	box-sizing border-box
	overflow auto
	//resize both
	//background #333
	//background var(--vscode-editorPane-background)
	//background var(--vscode-dropdown-background)
	background var(--vscode-editorWidget-background)
	border 1px solid var(--vscode-editorWidget-border)
	//--vscode-dropdown-listBackground
	border-radius 5px
	box-shadow: 0 0 5px solid #000
.titlebar, .close
	line-height 2em
	margin-top 1vmax
.titlebar
	color #80808020
.close
	position absolute
	top 0
	right 1.3vmax
	font-family revert
.popup-content
	padding 0 2vmax 3vmax
	overflow auto
	height fit-content
</style>
