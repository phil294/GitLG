import { ref, computed, shallowRef } from 'vue'
import default_git_actions from './default-git-actions.json'
import { parse } from './log-utils.js'
import { git, exchange_message, add_push_listener } from '../bridge.js'
import GitInputModel, { parse_config_actions } from './GitInput.js'

/**
 * @typedef {import('./types').GitRef} GitRef
 * @typedef {import('./types').Branch} Branch
 * @typedef {import('./types').Commit} Commit
 * @typedef {import('./types').ConfigGitAction} ConfigGitAction
 * @typedef {import('./types').GitAction} GitAction
 * @typedef {import('./types').HistoryEntry} HistoryEntry
 */
/** @template T @typedef {import('vue').Ref<T>} Ref */
/** @template T @typedef {import('vue').ComputedRef<T>} ComputedRef */
/** @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef */

// ########################
// This file should be used for state that is of importance for more than just one component.
// It encompasses state, actions and getters (computed values).
// ########################

/** @type {Record<string, WritableComputedRef<any>>} */
let _stateful_computeds = {}
add_push_listener('state-update', ({ data: { key, value } }) => {
	if (_stateful_computeds[key])
		_stateful_computeds[key].value = value
})
/** @template T
 * This utility returns a `WritableComputed` that will persist its state or react to changes on the
 * backend somehow. The caller doesn't know where it's stored though, this is up to extension.js
 * to decide based on the *key*.
 */
export let stateful_computed = (/** @type {string} */ key, /** @type {T} */ default_value, /** @type {()=>any} */ on_load) => {
	/** @type {WritableComputedRef<T>|undefined} */
	let ret = _stateful_computeds[key]
	if (ret) {
		on_load()
		return ret
	}
	// shallow because type error https://github.com/vuejs/composition-api/issues/483
	let internal = shallowRef(default_value)
	ret = computed({
		get: () => internal.value,
		set(/** @type {T} */ value) {
			if (internal.value !== value)
				exchange_message('set-state', { key, value })
			internal.value = value
		},
	})
	_stateful_computeds[key] = ret;
	(async () => {
		let stored = await exchange_message('get-state', key)
		if (stored != null) {
			internal.value = stored // to skip the unnecessary roundtrip to backend
			ret.value = stored
		}
		on_load?.()
	})()
	return ret
}

/** @type {Ref<Commit[]|null>} */
export let commits = ref(null)

/** @type {Ref<Branch[]>} */
export let branches = ref([])
// this is either a branch id(name) or HEAD in which case it will simply not be shown
// which is also not necessary because HEAD is then also visible as a branch tip.
export let head_branch = ref('')
export let git_status = ref('')
/** @type {Ref<string|null>} */
export let default_origin = ref('')

export let git_run_log = async (/** @type string */ log_args) => {
	let sep = '^%^%^%^%^'
	log_args = log_args.replace(' --pretty={EXT_FORMAT}', ` --pretty=format:"${sep}%H${sep}%h${sep}%aN${sep}%aE${sep}%ad${sep}%D${sep}%s"`)
	let stash_refs = await git('reflog show --format="%h" stash').catch(() => '')
	log_args = log_args.replace('{STASH_REFS}', stash_refs.replaceAll('\n', ' '))
	// errors will be handled by GitInput
	let [log_data, branch_data, stash_data, status_data, head_data] = await Promise.all([
		git(log_args),
		git(`branch --list --all --format="%(upstream:remotename)${sep}%(refname)"`),
		git('stash list --format="%h %gd"').catch(() => ''),
		git('-c core.quotepath=false status'),
		git('rev-parse --abbrev-ref HEAD'),
	])
	if (log_data == null)
		return
	let parsed = parse(log_data, branch_data, stash_data, sep, config.value['curve-radius'])
	commits.value = parsed.commits
	branches.value = parsed.branches
	head_branch.value = head_data
	git_status.value = status_data
	let likely_default_branch = branches.value.find((b) => b.name === 'master' || b.name === 'main') || branches.value[0]
	default_origin.value = likely_default_branch?.remote_name || likely_default_branch?.tracking_remote_name || null
}
/** @type {Ref<Ref<GitInputModel|null>|null>} */
export let main_view_git_input_ref = ref(null)
/** @param args {{before_execute?: ((cmd: string) => string) | undefined}} */
export let refresh_main_view = ({ before_execute } = {}) => {
	console.warn('refreshing main view')
	return main_view_git_input_ref.value?.value?.execute({ before_execute })
}

export let update_commit_stats = async (/** @type {Commit[]} */ commits) => {
	let data = await git('show --format="%h" --shortstat ' + commits.map((c) => c.hash).join(' '))
	if (! data)
		return
	let hash = ''
	for (let line of data.split('\n').filter(Boolean)) {
		if (! line.startsWith(' ')) {
			hash = line
			continue
		}
		let stat = { files_changed: 0, insertions: 0, deletions: 0 }
		//  3 files changed, 87 insertions(+), 70 deletions(-)
		for (let stmt of line.trim().split(', ')) {
			let words = stmt.split(' ')
			if (words[1].startsWith('file'))
				stat.files_changed = Number(words[0])
			else if (words[1].startsWith('insertion'))
				stat.insertions = Number(words[0])
			else if (words[1].startsWith('deletion'))
				stat.deletions = Number(words[0])
		}
		commits[commits.findIndex((cp) => cp.hash === hash)].stats = stat
	}
}

/** @type {Ref<GitAction|null>} */
export let selected_git_action = ref(null)

/** @type {Ref<any>} */
export let config = ref({})
export let refresh_config = async () =>
	config.value = await exchange_message('get-config')

/** @type {Ref<ConfigGitAction[]>} */
export let global_actions = computed(() =>
	default_git_actions['actions.global'].concat(config.value.actions?.global || []))
export let commit_actions = (/** @type string */ hash) => computed(() => {
	let config_commit_actions = default_git_actions['actions.commit'].concat(config.value.actions?.commit || [])
	return parse_config_actions(config_commit_actions, [
		['{COMMIT_HASH}', hash],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let commits_actions = (/** @type string[] */ hashes) => computed(() => {
	let config_commits_actions = default_git_actions['actions.commits'].concat(config.value.actions?.commits || [])
	return parse_config_actions(config_commits_actions, [
		['{COMMIT_HASHES}', hashes.join(' ')],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let branch_actions = (/** @type Branch */ branch) => computed(() => {
	let config_branch_actions = default_git_actions['actions.branch'].concat(config.value.actions?.branch || [])
	return parse_config_actions(config_branch_actions, [
		['{BRANCH_NAME}', branch.id],
		['{LOCAL_BRANCH_NAME}', branch.name],
		['{REMOTE_NAME}', branch.remote_name || branch.tracking_remote_name || default_origin.value || 'MISSING_REMOTE_NAME'],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let tag_actions = (/** @type string */ tag_name) => computed(() => {
	let config_tag_actions = default_git_actions['actions.tag'].concat(config.value.actions?.tag || [])
	return parse_config_actions(config_tag_actions, [
		['{TAG_NAME}', tag_name],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let stash_actions = (/** @type string */ stash_name) => computed(() => {
	let config_stash_actions = default_git_actions['actions.stash'].concat(config.value.actions?.stash || [])
	return parse_config_actions(config_stash_actions, [
		['{STASH_NAME}', stash_name],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let combine_branches_actions = computed(() => {
	let config_combine_branches_actions = default_git_actions['actions.branch-drop'].concat(config.value.actions?.['branch-drop'] || [])
	return parse_config_actions(config_combine_branches_actions, [
		['{SOURCE_BRANCH_NAME}', combine_branches_from_branch_name.value],
		['{TARGET_BRANCH_NAME}', combine_branches_to_branch_name.value],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})

export let combine_branches_to_branch_name = ref('')
export let combine_branches_from_branch_name = ref('')
export let combine_branches = (/** @type string */ from_branch_name, /** @type string */ to_branch_name) => {
	if (from_branch_name === to_branch_name)
		return
	combine_branches_to_branch_name.value = to_branch_name
	combine_branches_from_branch_name.value = from_branch_name
}

export let show_branch = (/** @type Branch */ branch_tip) =>
	refresh_main_view({
		before_execute: (cmd) =>
			`${cmd} ${branch_tip.id}`.replaceAll(' --all ', ' ').replaceAll(' {STASH_REFS} ', ' '),
	})

export let vis_v_width = computed(() =>
	Number(config.value['branch-width']) || 10)
export let vis_width = stateful_computed('vis-width', 130)

/** @type {HistoryEntry[]} */
let default_history = []
export let history = stateful_computed('repo:action-history', default_history)
export let push_history = (/** @type HistoryEntry */ entry) => {
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

export let init = () => {
	refresh_config()

	add_push_listener('config-change', async () => {
		await refresh_config()
		refresh_main_view()
	})

	// todo rm =>s v
	add_push_listener('repo-external-state-change', () => refresh_main_view())

	add_push_listener('refresh-main-view', () => refresh_main_view())
}
