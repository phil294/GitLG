<template lang="slm">
div
	promise-form#log-input.fill-w.row.center.gap-10 :action="do_log"
		code git 
		input v-model="log_args"
		button →
	pre.padding-l v-if="log_error"
		| Command failed: 
		| {{ log_error }}
	.row
		ul#commits
			li v-for="commit of commits"
				| {{ commit }}
</template>

<script lang="coffee">
import store from '../store.coffee'
import { ref } from 'vue'

export default
	setup: ->
		log_args = ref 'log --graph --all --decorate --oneline --source'
		log_error = ref ''
		do_log = =>
			try
				log_error.value = ''
				await store.do_log log_args.value
			catch e
				log_error.value = JSON.stringify e, null, 4
		do_log()
		
		{
			commits: store.commits
			do_log
			log_args
			log_error
		}
</script>

<style lang="stylus">
#log-input
	input
		padding 0 7px
</style>