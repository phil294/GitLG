<template>
	<div id="repo-selection">
		<vscode-single-select ref="select_ref" :options="repo_names.map((repo_name, index) => ({ label: repo_name, value: index }))" :value="selection" @change="selection = $event.target.value" />
	</div>
</template>
<script setup>
import { watch } from 'vue'
import { stateful_computed, refresh_main_view } from '../state/store.js'

let repo_names = stateful_computed('repo-names', ['Loading...'])
/** @type {Vue.WritableComputedRef<number>} */
let selection = stateful_computed('selected-repo-index', 0, () =>
	watch(selection, () => refresh_main_view()))
</script>
<style>
	vscode-single-select {
		width: 160px;
		--dropdown-z-index: 3;
	}
</style>
