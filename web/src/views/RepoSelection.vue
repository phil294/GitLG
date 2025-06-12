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
import { stateful_computed, refresh_main_view } from '../state/store.js'

let repo_names = stateful_computed('repo-names')
/** @type {Vue.WritableComputedRef<number>} */
let selection = stateful_computed('selected-repo-index', 0, () =>
	watch(selection, () => refresh_main_view()))
</script>
