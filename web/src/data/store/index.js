import { computed, nextTick, ref, watch } from 'vue'
import { add_push_listener, show_information_message } from '../../bridge.js'
import state, { refresh_repo_states } from '../state.js'
import * as repo_store from './repo.js'

export let web_phase = state('web-phase', 'initializing').ref

/** @type {Vue.Ref<Readonly<Vue.ShallowRef<typeof import('../../components/GitInput.vue')|null>>|null>} */
export let main_view_git_input_ref = ref(null)
export let main_view_highlight_refresh_button = ref(false)
/** @param options {{custom_log_args?: ((log_args: { user_log_args: string, default_log_args: string, base_log_args: string}) => string) | undefined, fetch_stash_refs?: boolean, fetch_branches?: boolean}} @returns {Promise<void>}} */
export let trigger_main_refresh = (options = {}) => {
	console.warn('refreshing main view')
	main_view_highlight_refresh_button.value = !! options.custom_log_args
	// @ts-ignore TODO: types seem correct like hinted by docs https://vuejs.org/guide/typescript/composition-api.html#typing-component-template-refs
	// but volar doesn't like it
	return main_view_git_input_ref.value?.value?.execute({
		...options,
		before_execute: (/** @type {string} */ cmd) => options.custom_log_args?.({
			user_log_args: cmd,
			default_log_args: repo_store.log_action.args,
			base_log_args: repo_store.base_log_args,
		}) || cmd,
	})
}

/** @param log_args {string} @param options {{ fetch_stash_refs?: boolean, fetch_branches?: boolean }} */
export let _run_main_refresh = async (log_args, { fetch_stash_refs, fetch_branches } = {}) => {
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
	await repo_store._protected.refresh(log_args, { preliminary_loading, fetch_stash_refs, fetch_branches })
	web_phase.value = 'ready'
}

export let repo_infos = state('repo-infos', []).ref
let selected_repo_path_is_valid = computed(() =>
	repo_infos.value.some(i => i.path === selected_repo_path.value))
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

/** @type {Vue.Ref<GitAction|null>} */
export let selected_git_action = ref(null)

export let config = state('config', {}).ref

export let vis_v_width = computed(() =>
	Number(config.value['branch-width']) || 10)
export let vis_width = state('vis-width', 130).ref

export let combine_branches_to_branch_name = ref('')
export let combine_branches_from_branch_name = ref('')
// TODO: should be id not name (?)
export let combine_branches = (/** @type {string} */ from_branch_name, /** @type {string} */ to_branch_name) => {
	if (from_branch_name === to_branch_name)
		return
	combine_branches_to_branch_name.value = to_branch_name
	combine_branches_from_branch_name.value = from_branch_name
}

// TODO: rename / distinguish from scroll_to_/jump_to_branch_tip. show_isolate_branch?. same below which is actually even called from a jump_to_*.
export let show_branch = (/** @type {Branch} */ branch_tip) =>
	trigger_main_refresh({
		custom_log_args: ({ base_log_args }) =>
			`${base_log_args} -n 15000 ${branch_tip.id}`,
		fetch_branches: false,
		fetch_stash_refs: false,
	})

/** Make sure *hash* is temporarily part of the loaded commits */
export let show_commit_hash = async (/** @type {string} */ hash) => {
	await trigger_main_refresh({
		custom_log_args: ({ base_log_args }) =>
			`${base_log_args} -n 500 ${hash}`,
		fetch_stash_refs: false,
		fetch_branches: false,
	})
	show_information_message(`The commit '${hash}' wasn't loaded, so GitLG jumped back in time temporarily. To see the previous configuration, click reload at the top right.`)
	main_view_highlight_refresh_button.value = true
	await nextTick()
}

add_push_listener('repo-external-state-change', () => trigger_main_refresh())

add_push_listener('refresh-main-view', () => trigger_main_refresh())

watch(config, async () => {
	web_phase.value = 'initializing_repo'
	trigger_main_refresh()
})
