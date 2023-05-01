import { defineComponent, watch, ref } from 'vue'
import { set_selected_folder_index, get_selected_folder_index } from '../bridge.coffee'
import { folder_names, refresh_main_view } from './store.coffee'

export default defineComponent
	setup: ->
		selection = ref 0
		do =>
			selection.value = await get_selected_folder_index()
		watch selection, =>
			set_selected_folder_index(selection.value)
			refresh_main_view()
		{
			selection
			folder_names
		}