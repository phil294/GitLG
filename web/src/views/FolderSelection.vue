<template lang="slm">
#folder-selection
	select v-model="selection"
		option v-for="folder_name, i of folder_names" :value="i"
			| {{ folder_name }}
</template>

<script lang="coffee" src="./FolderSelection.coffee"></script>

<style lang="stylus">
</style>