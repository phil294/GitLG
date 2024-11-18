import { ref, computed, shallowRef } from 'vue'
import { parse } from '../utils/log-parser.js'
import { git, exchange_message, add_push_listener, show_information_message } from '../bridge.js'
export { update_commit_stats } from './commit-stats'
export { global_actions, commit_actions, commits_actions, branch_actions, tag_actions, stash_actions, combine_branches_actions } from './actions.js'

// ########################
// This file should be used for state that is of importance for more than just one component.
// It encompasses state, actions and getters (computed values).
// ########################

/** @type {Record<string, Vue.WritableComputedRef<any>>} */
let _stateful_computeds = {}
add_push_listener('state-update', ({ data: { key, value } }) => {
	if (_stateful_computeds[key])
		_stateful_computeds[key].value = value
})
/**
 * @template T
 * This utility returns a `WritableComputed` that will persist its state or react to changes on the
 * backend somehow. The caller doesn't know where it's stored though, this is up to extension.js
 * to decide based on the *key*.
 */
export let stateful_computed = (/** @type {string} */ key, /** @type {T} */ default_value, /** @type {()=>any} */ on_load = () => {}) => {
	/** @type {Vue.WritableComputedRef<T>|undefined} */
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

/** @type {Vue.Ref<Commit[]|null>} */
export let commits = ref(null)

/** @type {Vue.Ref<Branch[]>} */
export let branches = ref([])
// this is either a branch id(name) or HEAD in which case it will simply not be shown
// which is also not necessary because HEAD is then also visible as a branch tip.
export let head_branch = ref('')
export let git_status = ref('')
/** @type {Vue.Ref<string|null>} */
export let default_origin = ref('')

export let log_action = {
	// regarding the -greps: Under normal circumstances, when showing stashes in
	// git log, each of the stashes 2 or 3 parents are being shown. That because of
	// git internals, but they are completely useless to the user.
	// Could not find any easy way to skip those other than de-grepping them, TODO:.
	// Something like `--exclude-commit=stash@{...}^2+` doesn't exist.
	args: 'log --graph --oneline --date=iso-local --pretty={EXT_FORMAT} -n 15000 --skip=0 --all {STASH_REFS} --color=never --invert-grep --extended-regexp --grep="^untracked files on " --grep="^index on "',
	options: [
		{ value: '--decorate-refs-exclude=refs/remotes', default_active: false, info: 'Hide remote branches' },
		{ value: '--grep="^Merge (remote[ -]tracking )?(branch \'|pull request #)"', default_active: false, info: 'Hide merge commits' },
		{ value: '--date-order', default_active: false, info: 'Show no parents before all of its children are shown, but otherwise show commits in the commit timestamp order.' },
		{ value: '--author-date-order', default_active: true, info: 'Show no parents before all of its children are shown, but otherwise show commits in the author timestamp order.' },
		{ value: '--topo-order', default_active: false, info: 'Show no parents before all of its children are shown, and avoid showing commits on multiple lines of history intermixed.' },
		{ value: '--reflog', default_active: false, info: 'Pretend as if all objects mentioned by reflogs are listed on the command line as <commit>. / Reference logs, or "reflogs", record when the tips of branches and other references were updated in the local repository. Reflogs are useful in various Git commands, to specify the old value of a reference. For example, HEAD@{2} means "where HEAD used to be two moves ago", master@{one.week.ago} means "where master used to point to one week ago in this local repository", and so on. See gitrevisions(7) for more details.' },
		{ value: '--simplify-by-decoration', default_active: false, info: 'Allows you to view only the big picture of the topology of the history, by omitting commits that are not referenced by some branch or tag. Can be useful for very large repositories.' }],
	config_key: 'main-log',
	immediate: true,
}
/** For when the extension needs to display something without the user being allowed to intervene. A default to be extended. */
let log_args_override_base = 'log --graph --author-date-order --date=iso-local --pretty={EXT_FORMAT} --color=never'

/**
 * This function usually shouldn't be called in favor of `refresh_main_view()` because the latter
 * allows the user to edit the arg, shows loading animation, prints errors accordingly etc.
 */
async function git_log(/** @type {string} */ log_args, { fetch_stash_refs = true, fetch_branches = true } = {}) {
	let sep = '^%^%^%^%^'
	log_args = log_args.replace(' --pretty={EXT_FORMAT}', ` --pretty=format:"${sep}%H${sep}%h${sep}%aN${sep}%aE${sep}%ad${sep}%D${sep}%s" --decorate=full `)
	let stash_refs = ''
	if (fetch_stash_refs)
		stash_refs = await git('stash list --format="%h"')
	log_args = log_args.replace('{STASH_REFS}', stash_refs.replaceAll('\n', ' '))
	let [log_data, branch_data, stash_data] = await Promise.all([
		git(log_args),
		fetch_branches ? git(`branch --list --all --format="%(upstream:remotename)${sep}%(refname)"`) : '',
		fetch_stash_refs ? git('stash list --format="%h %gd"', { ignore_errors: true }).catch(() => '') : '',
	])
	/** @type {Awaited<ReturnType<parse>>} */
	let parsed = { commits: [], branches: [] }
	if (log_data)
		parsed = await parse(log_data, branch_data, stash_data, sep, config.value['curve-radius'])
	return parsed
}

export let main_view_action = async (/** @type {string} */ log_args) => {
	if (web_phase.value !== 'initializing')
		web_phase.value = 'refreshing'
	// errors will be handled by GitInput
	let [parsed_log_data, status_data, head_data] = await Promise.all([
		git_log(log_args).catch(error => {
			show_information_message('Git LOG failed. Did you change the command by hand? In the main view at the top left, click "Configure", then at the top right click "Reset", then "Save" and try again. If this didn\'t help, it might be a bug! Please open up a GitHub issue.')
			throw error
		}),
		git('-c core.quotepath=false status'),
		git('symbolic-ref HEAD', { ignore_errors: true }).maybe(),
	])
	commits.value = parsed_log_data.commits
	branches.value = parsed_log_data.branches
	head_branch.value = head_data || 'refs/heads/HEAD'
	git_status.value = status_data
	let likely_default_branch = branches.value.find((b) => b.name === 'master' || b.name === 'main') || branches.value[0]
	default_origin.value = likely_default_branch?.remote_name || likely_default_branch?.tracking_remote_name || null
	web_phase.value = 'ready'
}
/** @type {Vue.Ref<Readonly<Vue.ShallowRef<InstanceType<typeof import('./GitInput.vue')>|null>>|null>} */
export let main_view_git_input_ref = ref(null)
/** @param args {{before_execute?: ((cmd: string) => string) | undefined}} */
export let refresh_main_view = ({ before_execute } = {}) => {
	console.warn('refreshing main view')
	return main_view_git_input_ref.value?.value?.execute({ before_execute })
}

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
	let { commits: _commits } = await git_log(`${log_args_override_base} -n 500 ${hash}`, { fetch_stash_refs: false, fetch_branches: false })
	commits.value = _commits
	show_information_message(`The commit '${hash}' wasn't loaded, so GitLG jumped back in time temporarily. To see the previous configuration, click reload at the top right.`)
}

export let web_phase = stateful_computed('web-phase', /** @type {'dead' | 'initializing' | 'ready' | 'refreshing'} */ ('initializing')) // eslint-disable-line @stylistic/no-extra-parens

export let init = () => {
	refresh_config().then(() => {
		if (config.value['disable-preliminary-loading'])
			return
		// The "main" main log happens via the `immediate` flag of log_action which is rendered in a git-input in MainView.
		// But because of the large default_log_action_n, this can take several seconds for large repos.
		// This below is a bit of a pre-flight request optimized for speed to show the first few commits while the rest keeps loading in the background.
		git_log(`${log_args_override_base} -n 100 --all`,
			{ fetch_stash_refs: false, fetch_branches: false }).then((parsed) =>
			commits.value = parsed.commits
				.concat({ subject: '..........Loading more..........', author_email: '', hash: '-', index_in_graph_output: -1, vis_lines: [{ y0: 0.5, yn: 0.5, x0: 0, xn: 2000, branch: { color: 'yellow', type: 'branch', name: '', display_name: '', id: '' } }], author_name: '', hash_long: '', refs: [] })
				.map(c => ({ ...c, stats: /* to prevent loading them */ {} })))
	})

	add_push_listener('config-change', async () => {
		await refresh_config()
		refresh_main_view()
	})

	add_push_listener('repo-external-state-change', () => refresh_main_view())

	add_push_listener('refresh-main-view', () => refresh_main_view())
}
