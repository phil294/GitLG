<template lang="slm">
.row
	ul#commits
		li v-for="commit of commits"
			| {{ commit }}
</template>

<script lang="coffee">
import store from '../store.coffee'

export default
	setup: ->
		store.ready()
		
		commits: store.commits
</script>

<style lang="stylus">
</style>