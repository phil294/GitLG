import { defineComponent, watch } from 'vue'
import { stateful_computed, refresh_main_view } from './store.js'

export default defineComponent({
	setup() {
		let repo_names = stateful_computed('repo-names')
		let selection = stateful_computed('selected-repo-index', 0, () =>
			watch(selection, refresh_main_view))

		return { selection, repo_names }
	},
})
