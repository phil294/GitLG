import { computed, ref, watch } from 'vue'
import { add_push_listener, exchange_message, show_information_message } from '../../bridge.js'
import state, { refresh_repo_states } from '../state.js'
import * as repo_store from './repo.js'
export { update_commit_stats } from '../commit-stats'

/** @type {Vue.Ref<Readonly<Vue.ShallowRef<typeof import('../../views/GitInput.vue')|null>>|null>} */
export let main_view_git_input_ref = ref(null)
export let main_view_highlight_refresh_button = ref(false)
/** @param args {{before_execute?: ((cmd: string) => string) | undefined}} @returns {Promise<void>}} */
export let trigger_main_refresh = ({ before_execute } = {}) => {
	console.warn('refreshing main view')
	main_view_highlight_refresh_button.value = !! before_execute
	// @ts-ignore TODO: types seem correct like hinted by docs https://vuejs.org/guide/typescript/composition-api.html#typing-component-template-refs
	// but volar doesn't like it
	return main_view_git_input_ref.value?.value?.execute({ before_execute })
}

export let web_phase = state('web-phase', /** @type {'dead' | 'initializing' | 'initializing_repo' | 'ready' | 'refreshing'} */ ('initializing')).ref

export let _run_main_refresh = async (/** @type {string} */ log_args) => {
	let preliminary_loading = false
	if (web_phase.value === 'initializing')
		web_phase.value = 'initializing_repo'
	else if (web_phase.value !== 'initializing_repo')
		web_phase.value = 'refreshing'
	if (web_phase.value === 'initializing_repo') {
		repo_store._protected.unset()
		if (! selected_repo_path_is_valid.value)
			return web_phase.value = 'ready'
		refresh_repo_states()
		preliminary_loading = ! config.value['disable-preliminary-loading']
	}
	repo_store._protected.refresh(log_args, preliminary_loading)
	web_phase.value = 'ready'
}

/** @type {Vue.WritableComputedRef<{path: string, name: string}[]>} */
export let repo_infos = state('repo-infos').ref
/** @type {Vue.WritableComputedRef<string>} */
export let selected_repo_path = state('selected-repo-path', '', () => {
	watch([selected_repo_path, selected_repo_path_is_valid], () => {
		web_phase.value = 'initializing_repo'
		trigger_main_refresh()
		// TODO: eager?
	})
	if (! selected_repo_path.value && repo_infos.value.length) // first extension run
		selected_repo_path.value = not_null(repo_infos.value[0]).path
}).ref
let selected_repo_path_is_valid = computed(() =>
	repo_infos.value.some(i => i.path === selected_repo_path.value))

/** @type {Vue.Ref<GitAction|null>} */
export let selected_git_action = ref(null)

/** @type {Vue.Ref<any>} */
export let config = ref({})
export let refresh_config = async () =>
	config.value = await exchange_message('get-config')

export let combine_branches_to_branch_name = ref('')
export let combine_branches_from_branch_name = ref('')
// should be id not name (?)
export let combine_branches = (/** @type {string} */ from_branch_name, /** @type {string} */ to_branch_name) => {
	if (from_branch_name === to_branch_name)
		return
	combine_branches_to_branch_name.value = to_branch_name
	combine_branches_from_branch_name.value = from_branch_name
}

export let show_branch = (/** @type {Branch} */ branch_tip) =>
	trigger_main_refresh({
		before_execute: (cmd) =>
			`${cmd} ${branch_tip.id}`.replaceAll(' --all ', ' ').replaceAll(' {STASH_REFS} ', ' '),
	})

export let vis_v_width = computed(() =>
	Number(config.value['branch-width']) || 10)
export let vis_width = state('vis-width', 130).ref

/** @type {HistoryEntry[]} */
let default_history = []
export let history = state('repo:action-history', default_history).ref
export let push_history = (/** @type {HistoryEntry} */ entry) => {
	entry.datetime = new Date().toISOString()
	let _history = history.value?.slice() || []
	let last_entry = _history.at(-1)
	switch (entry.type) {
		case 'git':
			if (entry.value.startsWith('log '))
				return
	}
	if (last_entry?.type === entry.type)
		switch (entry.type) {
			case 'txt_filter':
				if (last_entry?.value === entry.value)
					return
				if (last_entry)
					last_entry.value = entry.value
				break
			case 'branch_id': case 'commit_hash': case 'git':
				if (last_entry?.value === entry.value)
					return
				_history.push(entry)
				break
			default:
				throw `Unexpected history entry type ${entry.type}`
		}
	else
		_history.push(entry)
	if (_history.length > 100)
		_history.shift()
	history.value = _history
}

/** Make sure *hash* is temporarily part of the loaded commits */
export let load_commit_hash = async (/** @type {string} */ hash) => {
	repo_store._protected.refresh_for_hash(hash)
	show_information_message(`The commit '${hash}' wasn't loaded, so GitLG jumped back in time temporarily. To see the previous configuration, click reload at the top right.`)
	main_view_highlight_refresh_button.value = true
}

export let init = () => {
	repo_store._protected.unset()

	refresh_config()

	add_push_listener('config-change', async () => {
		web_phase.value = 'initializing_repo'
		await refresh_config()
		trigger_main_refresh()
	})

	add_push_listener('repo-external-state-change', () => trigger_main_refresh())

	add_push_listener('refresh-main-view', () => trigger_main_refresh())
}
