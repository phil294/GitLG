import { defineComponent, watch, ref } from 'vue'
import { exchange_message } from '../bridge.coffee'
import { repo_names, refresh_main_view } from './store.coffee'

export default defineComponent
	setup: ->
		selection = ref 0
		do =>
			selection.value = Number((await exchange_message 'get-selected-repo-index'))
		watch selection, =>
			exchange_message 'set-selected-repo-index', selection.value
			refresh_main_view()
		{
			selection
			repo_names
		}