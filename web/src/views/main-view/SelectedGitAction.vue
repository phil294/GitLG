<template>
	<div class="selected-git-action">
		<h2>
			<template v-if="title">
				{{ title }} -&nbsp;
			</template>
			{{ selected_git_action?.description }}
		</h2>
		<details v-if="selected_git_action?.info" class="padding">
			<summary>
				{{ selected_git_action.info }}
			</summary>
			{{ selected_git_action.info }}
		</details>
		<git-input v-if="selected_git_action" :git_action="selected_git_action" @executed="trigger_main_refresh()" @success="success()" />
		<br>
		<label class="row align-center gap-5">
			<input v-model="keep_open" type="checkbox">
			Keep window open after success
		</label>
	</div>
</template>
<script setup>
import { ref } from 'vue'
import { selected_git_action, trigger_main_refresh } from '../../data/store'
import vue_resolved from '../../utils/vue-resolved'

let keep_open = ref(false)

function success() {
	if (! keep_open.value)
		selected_git_action.value = null
}
let title = vue_resolved(selected_git_action.value?.title())
</script>
<style>
.selected-git-action {
	width: clamp(200px, 50vw, 50vw);
}
.selected-git-action > details {
	white-space: pre-line;
}
.selected-git-action > details > summary {
	overflow: hidden;
	text-overflow: ellipsis;
	color: var(--text-secondary);
}
</style>
