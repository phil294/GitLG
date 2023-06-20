import { ref, defineComponent } from 'vue'
import { selected_git_action, refresh_main_view } from './store.coffee'
import GitInput from './GitInput.vue'

export default defineComponent
	components: { GitInput }
	setup: ->
		keep_open = ref false

		success = =>
			if not keep_open.value
				selected_git_action.value = null

		{
			keep_open
			success
			refresh_main_view
			selected_git_action
		}