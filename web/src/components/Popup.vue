<template>
	<div class="modal popup">
		<Teleport to="body">
			<div :bind="$attrs" :tabindex="-1" class="modal-body center fade-in" @keydown.esc="close">
				<div class="modal-background fill" @click="close" />
				<div ref="main_ref" class="modal-main col">
					<header>
						<div v-moveable="{move_target: main_ref}" class="titlebar center">
							⠿⠿⠿⠿⠿
						</div>
						<button class="close center" type="button" @click="close">
							<i class="codicon codicon-close" />
						</button>
					</header>
					<div class="popup-content">
						<slot />
					</div>
				</div>
			</div>
		</Teleport>
	</div>
</template>
<script setup>
import { onMounted, useTemplateRef } from 'vue'

defineOptions({
	inheritAttrs: false,
})
let emit = defineEmits(['close'])
let main_ref = /** @type {Readonly<Vue.ShallowRef<HTMLDivElement|null>>} */ (useTemplateRef('main_ref')) // eslint-disable-line @stylistic/no-extra-parens
onMounted(() => {
	main_ref.value?.focus()
})
function close() {
	emit('close')
}
</script>
<style scoped>
.modal-body {
	position: fixed;
	top: 0;
	left: 0;
	bottom: 0;
	right: 0;
	z-index: 9999;
	box-sizing: border-box;
	background: rgb(from var(--vscode-editor-foreground) r g b / 0.5);
}
.modal-background {
	position: absolute;
}
.modal-main {
	max-height: 98vh;
	max-width: 98vw;
	min-width: 50px;
	position: relative;
	box-sizing: border-box;
	overflow: auto;
	background: var(--vscode-editor-background);
}
.titlebar,
.close {
	line-height: 2em;
	margin-top: 1vmax;
}
.titlebar {
	color: rgba(128,128,128,0.125);
}
.close {
	position: absolute;
	top: 0;
	right: 1.3vmax;
	font-family: revert;
	height: 26px;
	width: 26px;
}
.popup-content {
	padding: 0 24px 24px;
	overflow: auto;
	height: fit-content;
}
header {
	position: absolute;
	top: 0;
	left: 0;
	right: 0;
}
</style>
