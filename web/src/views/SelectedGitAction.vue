<template>
	<div class="selected-git-action">
		<h2>
			<template v-if="selected_git_action?.title">
				{{ selected_git_action.title }} -&nbsp;
			</template>
			{{ selected_git_action?.description }}
		</h2>
		<details v-if="selected_git_action?.info" class="padding">
			<summary>
				{{ selected_git_action.info }}
			</summary>
			{{ selected_git_action.info }}
		</details>
		<git-input v-if="selected_git_action" :git_action="selected_git_action" @executed="refresh_main_view()" @success="success()" />
		<br>
		<label class="row align-center gap-5">
			<input v-model="keep_open" type="checkbox">
			Keep window open after success
		</label>
	</div>
</template>
<script setup>
import { ref } from 'vue'
import { selected_git_action, refresh_main_view } from '../state/store.js'

let keep_open = ref(false)

function success() {
	if (! keep_open.value)
		selected_git_action.value = null
}
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
