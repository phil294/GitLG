<!-- visual representation of a GitAction, resolving to a Button and onclick a Popup with GitInput inside -->
<template>
	<button :title="git_action.description" class="git-action-button btn gap-5" @click="selected_git_action=git_action">
		<div v-if="git_action.icon" class="icon center">
			<i :class="'codicon-'+git_action.icon" class="codicon" />
		</div>
		<div v-if="title" class="title">
			{{ title }}
		</div>
	</button>
</template>
<script setup>
import { ref } from 'vue'
import { on_trigger_main_refresh, selected_git_action } from '../data/store'
defineOptions({
	inheritAttrs: false,
})
let props = defineProps({
	git_action: {
		/** @type {Vue.PropType<GitAction>} */
		type: Object,
		required: true,
	},
})
let title = ref('Loading...')
let refresh_title = () =>
	props.git_action.title().then(t =>
		title.value = t)
refresh_title()
on_trigger_main_refresh(refresh_title)
</script>
<style>

</style>
