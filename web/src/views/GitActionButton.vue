<template lang="slm">
button.btn.gap-5 @click="selected_git_action=git_action" :title="git_action.description"
	.icon.center v-if="git_action.icon"
		i.codicon :class="'codicon-'+git_action.icon"
	.title v-if="git_action.title"
		| {{ git_action.title }}
</template>

<script lang="coffee" src="./GitActionButton.coffee"></script>

<style lang="stylus">
</style>