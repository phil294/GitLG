import { defineComponent, watch, ref } from 'vue'
import { exchange_message } from '../bridge.coffee'
import { folder_names, refresh_main_view } from './store.coffee'

export default defineComponent
	setup: ->
		selection = ref 0
		do =>
			selection.value = Number((await exchange_message 'get-selected-folder-index'))
		watch selection, =>
			exchange_message 'set-selected-folder-index', selection.value
			refresh_main_view()
		{
			selection
			folder_names
		}