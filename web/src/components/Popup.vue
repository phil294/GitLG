<template>
	<div class="modal popup">
		<Teleport to="body">
			<div :bind="$attrs" :tabindex="-1" class="modal-body center fade-in" @keydown.esc="close">
				<div class="modal-background fill" @click="close" />
				<div ref="main_ref" class="modal-main col">
					<header>
						<div v-moveable="{move_target}" class="titlebar center">
							⠿⠿⠿⠿⠿
						</div>
						<button class="close" type="button" @click="close">
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
<script>
import { ref, onMounted } from 'vue'
export default {

	inheritAttrs: false,
	emits: ['close'],
	setup(props, { emit }) {
		let move_target = ref(null)
		let main_ref = ref(null)
		onMounted(() => {
			move_target.value = main_ref.value
			main_ref.value.focus()
		})
		return {
			move_target,
			main_ref,
			close() {
				emit('close')
			},
		}
	},
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
	background: rgba(0,0,0,0.9);
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
	resize: both;
	background: rgba(128,128,128,0.125);
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
}
.popup-content {
	padding: 0 2vmax 3vmax;
	overflow: auto;
	height: fit-content;
}
</style>
