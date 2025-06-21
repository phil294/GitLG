<template>
	<div id="all-branches">
		<details id="show-all-branches" ref="details_ref" class="center">
			<summary>
				All branches...
			</summary>
			<div class="dv">
				<input v-model="txt_filter" class="filter" placeholder="Filter branch name">
				<div class="branches">
					<button v-for="branch of filtered_branches" :key="branch.id" title="Jump to branch tip" @click="$emit('branch_selected',branch);">
						<ref-tip :git_ref="branch" />
					</button>
				</div>
			</div>
		</details>
	</div>
</template>
<script setup>
import { branches } from '../../data/store/repo'
import { ref, computed, onMounted, onUnmounted, useTemplateRef } from 'vue'

defineEmits(['branch_selected'])

let details_ref = /** @type {Readonly<Vue.ShallowRef<HTMLDetailsElement|null>>} */ (useTemplateRef('details_ref'))
let txt_filter = ref('')
let filtered_branches = computed(() => {
	if (! txt_filter.value)
		return branches.value
	else
		return branches.value.filter((branch) =>
			branch.display_name.toLowerCase().includes(txt_filter.value.toLowerCase()))
})
function on_mouse_up(/** @type {MouseEvent} */ event) {
	if (! (event.target instanceof Element) ||
				event.target.parentElement?.getAttribute('id') !== 'show-all-branches' &&
				! event.target.classList.contains('ref-tip') &&
				! event.target.classList.contains('filter') &&
				! event.target.querySelector('.ref-tip') &&
				! event.target.parentElement?.classList.contains('context-menu-wrapper'))
		details_ref.value?.removeAttribute('open')
}
onMounted(() =>
	document.addEventListener('mouseup', on_mouse_up))
onUnmounted(() =>
	document.removeEventListener('mouseup', on_mouse_up))

</script>
<style scoped>
details#show-all-branches > summary {
	display: flex;
	align-items: center;
	justify-content: end;
}
.dv {
	padding: 5px 10px 20px 20px;
}
.dv > button > .ref-tip.branch {
	margin: 2px;
	padding: 1px 6px;
}
input.filter {
	margin: 5px;
	float: right;
	width: unset !important;
}
</style>
