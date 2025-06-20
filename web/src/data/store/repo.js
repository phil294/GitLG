import { computed, ref } from 'vue'
import { git, show_information_message } from '../../bridge.js'
import { parse } from '../../utils/log-parser.js'
import { config } from './index.js'
import { _protected as search_protected } from './search'
import state from '../state.js'

/** @type {Vue.Ref<Commit[]|null>} */
export let loaded_commits = ref(null)

/** @type {Vue.Ref<Branch[]>} */
export let branches = ref([])
// this is either a branch id(name) or HEAD in which case it will simply not be shown
// which is also not necessary because HEAD is then also visible as a branch tip.
export let head_branch = ref('')
export let git_status = ref('')
/** @type {Vue.Ref<string|null>} */
export let default_origin = ref('')

let unset = () => {
	loaded_commits.value = null
	visible_commits.value = []
	branches.value = []
	head_branch.value = ''
	git_status.value = ''
	default_origin.value = ''
	// TODO: is history unset after this? / merge with refresh_repo_states?
}

export let base_log_args = 'log --graph --oneline --date=iso-local --pretty={EXT_FORMAT} --invert-grep --extended-regexp --grep="^untracked files on " --grep="^index on " --color=never'

export let log_action = {
	// regarding the -greps: Under normal circumstances, when showing stashes in
	// git log, each of the stashes 2 or 3 parents are being shown. That because of
	// git internals, but they are completely useless to the user.
	// Could not find any easy way to skip those other than de-grepping them, TODO:.
	// Something like `--exclude-commit=stash@{...}^2+` doesn't exist.
	args: `${base_log_args} --skip=0 -n 15000 --all {STASH_REFS}`,
	options: [
		{ value: '--decorate-refs-exclude=refs/remotes', default_active: false, info: 'Hide remote branches' },
		{ value: '--grep="^Merge (remote[ -]tracking )?(branch \'|pull request #)"', default_active: false, info: 'Hide merge commits' },
		{ value: '--date-order', default_active: false, info: 'Show no parents before all of its children are shown, but otherwise show commits in the commit timestamp order.' },
		{ value: '--author-date-order', default_active: true, info: 'Show no parents before all of its children are shown, but otherwise show commits in the author timestamp order.' },
		{ value: '--topo-order', default_active: false, info: 'Show no parents before all of its children are shown, and avoid showing commits on multiple lines of history intermixed.' },
		{ value: '--reflog', default_active: false, info: 'Pretend as if all objects mentioned by reflogs are listed on the command line as <commit>. / Reference logs, or "reflogs", record when the tips of branches and other references were updated in the local repository. Reflogs are useful in various Git commands, to specify the old value of a reference. For example, HEAD@{2} means "where HEAD used to be two moves ago", master@{one.week.ago} means "where master used to point to one week ago in this local repository", and so on. See gitrevisions(7) for more details.' },
		{ value: '--simplify-by-decoration', default_active: false, info: 'Allows you to view only the big picture of the topology of the history, by omitting commits that are not referenced by some branch or tag. Can be useful for very large repositories.' }],
	storage_key: 'main-log',
	immediate: false,
	params: () => Promise.resolve([]),
	title: '',
}

async function git_log(/** @type {string} */ log_args, { fetch_stash_refs = true, fetch_branches = true } = {}) {
	// TODO: \0
	let sep = '^%^%^%^%^'
	log_args = log_args.replace(' --pretty={EXT_FORMAT}', ` --pretty=format:"${sep}%H${sep}%h${sep}%aN${sep}%aE${sep}%ad${sep}%D${sep}%s" --decorate=full `)
	let stash_refs = ''
	if (fetch_stash_refs)
		stash_refs = await git('stash list --format="%h"')
	log_args = log_args.replace('{STASH_REFS}', stash_refs.replaceAll('\n', ' '))
	let [log_data, branch_data, stash_data] = await Promise.all([
		git(log_args),
		fetch_branches ? git(`branch --list --all --sort=-committerdate --format="%(upstream:remotename)${sep}%(refname)"`) : '',
		fetch_stash_refs ? git('stash list --format="%h %gd"', { ignore_errors: true }).catch(() => '') : '',
	])
	/** @type {Awaited<ReturnType<parse>>} */
	let parsed = { commits: [], branches: [] }
	if (log_data)
		parsed = await parse(log_data, branch_data, stash_data, sep, config.value['curve-radius'], config.value['branch-colors'], config.value['branch-color-strategy'] === 'name-based', config.value['branch-color-custom-mapping'])
	return parsed
}
/** @param log_args {string} @param options {{ preliminary_loading?: boolean, fetch_stash_refs?: boolean, fetch_branches?: boolean }} */
let refresh = async (log_args, { preliminary_loading, fetch_stash_refs, fetch_branches }) => {
	if (preliminary_loading)
	// The "main" main log happens below, but because of the large default_log_action_n, this can take several seconds for large repos.
	// This below is a bit of a pre-flight request optimized for speed to show the first few commits while the rest keeps loading in the background.
		git_log(`${base_log_args} -n 100 --all`,
			{ fetch_stash_refs: false, fetch_branches: false }).then((parsed) =>
			loaded_commits.value = parsed.commits
				.concat({ subject: '..........Loading more..........', author_email: '', hash: '-', vis_lines: [{ y0: 0.5, yn: 0.5, x0: 0, xn: 2000, branch: { color: 'yellow', type: 'branch', name: '', display_name: '', id: '' } }], author_name: '', hash_long: '', refs: [], index_in_graph_output: -1 })
				.map(c => ({ ...c, stats: /* to prevent loading them */ {} })))
	// errors will be handled by GitInput
	let [parsed_log_data, status_data, head_data] = await Promise.all([
		git_log(log_args, { fetch_stash_refs, fetch_branches }).catch(error => {
			show_information_message('Git LOG failed. Did you change the command by hand? In the main view at the top left, click "Configure", then at the top right click "Reset", then "Save" and try again. If this didn\'t help, it might be a bug! Please open up a GitHub issue.')
			throw error
		}),
		git('-c core.quotepath=false status'),
		git('symbolic-ref HEAD', { ignore_errors: true }).catch(() => null),
	])
	loaded_commits.value = parsed_log_data.commits
	branches.value = parsed_log_data.branches
	head_branch.value = head_data || 'refs/heads/HEAD'
	git_status.value = status_data
	let likely_default_branch = branches.value.find((b) => b.name === 'master' || b.name === 'main') || branches.value[0]
	default_origin.value = likely_default_branch?.remote_name || likely_default_branch?.tracking_remote_name || null
}

export let _protected = { unset, refresh }

/** Subset of `loaded_commits` */
export let filtered_commits = search_protected.filtered_commits

/** Aka in current viewport. Subset of `commits`. Managed by Scroller.vue only. @type {Vue.Ref<Commit[]>} */
export let visible_commits = ref([])

/** @type {string[]} */
let default_selected_commits_hashes = []
let selected_commits_hashes = state('repo:selected-commits-hashes', default_selected_commits_hashes).ref
/** Subset of `visible_commits` */
export let selected_commits = computed({
	get() {
		return selected_commits_hashes.value
			?.map((hash) => filtered_commits.value.find((commit) => commit.hash === hash))
			.filter(is_truthy) || []
	},
	set(new_selection) {
		selected_commits_hashes.value = new_selection.map((commit) => commit.hash)
	},
})
export let single_selected_commit = computed(() => {
	if (selected_commits.value.length === 1)
		return selected_commits.value[0]
})
