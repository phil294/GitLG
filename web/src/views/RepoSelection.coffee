import { defineComponent, watch } from 'vue'
import { stateful_computed, refresh_main_view } from './store.coffee'

export default defineComponent
	setup: ->
		repo_names = stateful_computed 'repo-names'
		selection = stateful_computed 'selected-repo-index', 0
		watch selection, refresh_main_view
		{
			selection
			repo_names
		}