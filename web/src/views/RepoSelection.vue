<template lang="slm">
#repo-selection
	select v-model="selection"
		option v-for="repo_name, i of repo_names" :value="i"
			| {{ repo_name }}
</template>

<script lang="coffee" src="./RepoSelection.coffee"></script>

<style lang="stylus">
</style>