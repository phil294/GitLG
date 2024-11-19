<!-- visual representation of a GitAction, resolving to a Button and onclick a Popup with GitInput inside -->
<template>
	<vscode-button :title="git_action.description" class="git-action-button btn-icon" @click="selected_git_action=git_action">
		<div class="align-center gap-5">
			<vscode-icon v-if="git_action.icon" :name="git_action.icon" />
			<div v-if="git_action.title" class="title">
				{{ git_action.title }}
			</div>
		</div>
	</vscode-button>
</template>
<script setup>
import { selected_git_action } from '../state/store.js'
defineOptions({
	inheritAttrs: false,
})
defineProps({
	git_action: {
		/** @type {Vue.PropType<GitAction>} */
		type: Object,
		required: true,
	},
})
</script>
<style>

</style>
