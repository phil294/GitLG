<!-- visual representation of a GitAction, resolving to a Button and onclick a Popup with GitInput inside -->
<template>
	<button :title="git_action.description" class="git-action-button btn gap-5" @click="selected_git_action=git_action">
		<div v-if="git_action.icon" class="icon center">
			<i :class="'codicon-'+git_action.icon" class="codicon" />
		</div>
		<div v-if="git_action.title" class="title">
			{{ git_action.title }}
		</div>
	</button>
</template>
<script setup>
import { selected_git_action } from '../data/store'
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
