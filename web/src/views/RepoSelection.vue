<template>
	<div id="repo-selection">
		<select v-if="repo_names?.length > 1" v-model="selection">
			<option v-for="repo_name, i of repo_names" :key="repo_name" :value="i">
				{{ repo_name }}
			</option>
		</select>
	</div>
</template>
<script setup>
import { watch } from 'vue'
import { refresh_main_view, state, web_phase } from '../state/store.js'

let repo_names = state('repo-names').ref
/** @type {Vue.WritableComputedRef<number>} */
let selection = state('selected-repo-index', 0, () =>
	watch(selection, () => {
		web_phase.value = 'initializing_repo'
		refresh_main_view()
	})).ref
</script>
