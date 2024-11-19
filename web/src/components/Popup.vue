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
	background: rgb(from var(--vscode-editorWidget-background) r g b / 0.9);
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
	box-shadow: 2px 2px 3px var(--vscode-editor-background);
}
.titlebar {
	color: rgba(128,128,128,0.125);
	margin-top: 5px;
}
.close {
	position: absolute;
	top: 7px;
	right: 10px;
	font-family: revert;
	height: 26px;
	width: 26px;
}
.popup-content {
	padding: 0 24px 24px;
	overflow: auto;
	height: fit-content;
}
</style>
