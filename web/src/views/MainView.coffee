import { ref, computed, watch, nextTick, onMounted } from 'vue'
import * as store from './store.js'
import { show_error_message, add_push_listener } from '../bridge.js'
import { is_truthy } from './types'
import GitInputModel from './GitInput.js'
import GitInput from './GitInput.vue'
import GitActionButton from './GitActionButton.vue'
import CommitDetails from './CommitDetails.vue'
import CommitsDetails from './CommitsDetails.vue'
import CommitRow from './CommitRow.vue'
import AllBranches from './AllBranches.vue'
import History from './History.vue'
import SelectedGitAction from './SelectedGitAction.vue'
import RefTip from './RefTip.vue'
import RepoSelection from './RepoSelection.vue'
export default {

	/**
   * @typedef {import('./types').Commit} Commit
   * @typedef {import('./types').Branch} Branch
   */
	/** @template T @typedef {import('vue').Ref<T>} Ref */

	components: { CommitDetails, CommitsDetails, GitInput, GitActionButton, AllBranches, RefTip, SelectedGitAction, RepoSelection, History, CommitRow },
	setup() {
		let details_panel_position = computed(() =>
			store.config.value['details-panel-position'])

		/** @type {string[]} */
		let default_selected_commits_hashes = []
		let selected_commits_hashes = store.stateful_computed('repo:selected-commits-hashes', default_selected_commits_hashes)
		let selected_commits = computed({
			get() {
				return selected_commits_hashes.value?.map((hash) => filtered_commits.value.find((commit) => commit.hash === hash)).filter(is_truthy) || []
			},
			set(commits) {
				selected_commits_hashes.value = commits.map((commit) => commit.hash)
			},
		})
		let selected_commit = computed(() => {
			if (selected_commits.value.length === 1)
				return selected_commits.value[0]
		})
		function commit_clicked(/** @type Commit */ commit, /** @type {MouseEvent | undefined} */ event) {
			if (! commit.hash)
				return

			let selected_index = selected_commits.value.indexOf(commit)
			if (event?.ctrlKey || event?.metaKey)
				if (selected_index > -1)
					selected_commits.value = selected_commits.value.filter((_, i) => i !== selected_index)
				else

					selected_commits.value = [...selected_commits.value, commit]
			else if (event?.shiftKey) {
				let total_index = filtered_commits.value.indexOf(commit)
				let last_total_index = filtered_commits.value.indexOf(selected_commits.value[selected_commits.value.length - 1])
				if (total_index > last_total_index && total_index - last_total_index < 1000)
					selected_commits.value = selected_commits.value.concat(filtered_commits.value.slice(last_total_index, total_index + 1).filter((commit) =>
						! selected_commits.value.includes(commit)))
			} else

				if (selected_index > -1)
					selected_commits.value = []
				else {
					selected_commits.value = [commit]
					return store.push_history({ type: 'commit_hash', value: commit.hash })
				}
		}

		let txt_filter = ref('')
		/** @type {Ref<'filter' | 'jump'>} */
		let txt_filter_type = ref('filter')
		let txt_filter_regex = store.stateful_computed('filter-options-regex', false)
		async function clear_filter() {
			txt_filter.value = ''
			if (selected_commit.value) {
				await nextTick()
				return scroll_to_commit(selected_commit.value)
			}
		}
		/** @type {Ref<HTMLElement | null>} */
		let txt_filter_ref = ref(null)
		function txt_filter_filter(/** @type Commit */ commit) {
			let ref1, str
			let search_for = txt_filter.value.toLowerCase()
			for (str of [commit.subject, commit.hash_long, commit.author_name, commit.author_email, ...commit.refs.map((r) => r.id)].map((s) => s.toLowerCase()))
				if (txt_filter_regex.value) {
					if (str?.match.maybe(search_for))
						return true
				} else if (str?.includes(search_for))

					return true
		}

		let initialized = computed(() => !! store.commits.value)
		let filtered_commits = computed(() => {
			if (! txt_filter.value || txt_filter_type.value === 'jump')
				return store.commits.value || []
			return (store.commits.value || []).filter(txt_filter_filter)
		})
		let txt_filter_last_i = -1
		document.addEventListener('keyup', (e) => {
			if (e.key === 'F3' || e.ctrlKey && e.key === 'f')
				txt_filter_ref.value?.focus()
			if (txt_filter.value && e.key === 'r' && e.altKey)
				txt_filter_regex.value = ! txt_filter_regex.value
		})
		let select_searched_commit_debouncer = -1
		function txt_filter_enter(/** @type KeyboardEvent */ event) {
			if (txt_filter_type.value === 'filter')
				return

			if (event.shiftKey) {
				let next = [...filtered_commits.value.slice(0, txt_filter_last_i)].reverse().findIndex(txt_filter_filter)
				if (next > -1) {
					let next_match_index = txt_filter_last_i - 1 - next
				} else

					next_match_index = filtered_commits.value.length - 1
			} else {
				next = filtered_commits.value.slice(txt_filter_last_i + 1).findIndex(txt_filter_filter)
				if (next > -1)
					next_match_index = txt_filter_last_i + 1 + next
				else

					next_match_index = 0
			}
			scroll_to_item_centered(next_match_index)
			txt_filter_last_i = next_match_index
			window.clearTimeout(select_searched_commit_debouncer)
			select_searched_commit_debouncer = window.setTimeout(() => {
				selected_commits.value = [filtered_commits.value[txt_filter_last_i]]
			}, 100)
		}
		watch(txt_filter, () => {
			if (txt_filter.value)
				return store.push_history({ type: 'txt_filter', value: txt_filter.value })
		})

		function scroll_to_branch_tip(/** @type Branch */ branch) {
			let first_branch_commit_i = filtered_commits.value.findIndex((commit) => {
				if (branch.inferred)
					return commit.vis_lines.some((vis_line) => vis_line.branch === branch)
				else

					return commit.refs.some((ref) => ref === branch)
			})
			if (first_branch_commit_i === -1)
				return show_error_message(`No commit found for branch ${branch.id}. Not enough commits loaded?`)
			if (branch.inferred)
			// We want to go the the actual merge commit, not the first any-commit where

			// this line appeared (could be entirely unrelated)

				first_branch_commit_i--
			scroll_to_item_centered(first_branch_commit_i)
			let commit = filtered_commits.value[first_branch_commit_i]
			// Not only scroll to tip, but also select it, so the behavior is equal to clicking on

			// a branch name in a commit's ref list.

			selected_commits.value = [commit]
			// For now, set history always to commit_hash as this also shows the branches. Might revisit some day TODO

			// if branch.inferred

			// 	store.push_history type: 'commit_hash', value: commit.hash

			// else

			// 	store.push_history type: 'branch_id', value: branch.id

			return store.push_history({ type: 'commit_hash', value: commit.hash })
		}
		function scroll_to_commit_hash(/** @type string */ hash) {
			let commit_i = filtered_commits.value.findIndex((commit) =>
				commit.hash === hash)
			if (commit_i === -1) {
				console.log(new Error().stack)
				return show_error_message(`No commit found for hash ${hash}. No idea why :/`)
			}
			scroll_to_item_centered(commit_i)
			selected_commits.value = [filtered_commits.value[commit_i]]
		}
		function scroll_to_commit_hash_user(/** @type string */ hash) {
			scroll_to_commit_hash(hash)
			return store.push_history({ type: 'commit_hash', value: hash })
		}
		function scroll_to_commit(/** @type Commit */ commit) {
			let commit_i = filtered_commits.value.findIndex((c) => c === commit)
			return scroll_to_item_centered(commit_i)
		}
		function scroll_to_top() {
			return commits_scroller_ref.value?.scrollToItem(0)
		}
		add_push_listener('scroll-to-selected-commit', () =>
			scroll_to_commit(selected_commit.value))

		/** @type {Ref<GitInputModel | null>} */
		let git_input_ref = ref(null)
		store.main_view_git_input_ref.value = git_input_ref
		let log_action = {
			// rearding the -greps: Under normal circumstances, when showing stashes in

			// git log, each of the stashes 2 or 3 parents are being shown. That because of

			// git internals, but they are completely useless to the user.

			// Could not find any easy way to skip those other than de-grepping them, TODO:.

			// Something like `--exclude-commit=stash@{...}^2+` doesn't exist.

			args: 'log --graph --oneline --date=iso-local --pretty={EXT_FORMAT} -n 15000 --skip=0 --all {STASH_REFS} --color=never --invert-grep --extended-regexp --grep="^untracked files on " --grep="^index on "',
			options: [{ value: '--decorate-refs-exclude=refs/remotes', default_active: false, info: 'Hide remote branches' }, { value: '--grep="^Merge (remote[ -]tracking )?.(branch \'|pull request #)"', default_active: false, info: 'Hide merge commits' }, { value: '--date-order', default_active: false, info: 'Show no parents before all of its children are shown, but otherwise show commits in the commit timestamp order.' }, { value: '--author-date-order', default_active: true, info: 'Show no parents before all of its children are shown, but otherwise show commits in the author timestamp order.' }, { value: '--topo-order', default_active: false, info: 'Show no parents before all of its children are shown, and avoid showing commits on multiple lines of history intermixed.' }, { value: '--reflog', default_active: false, info: 'Pretend as if all objects mentioned by reflogs are listed on the command line as <commit>. / Reference logs, or "reflogs", record when the tips of branches and other references were updated in the local repository. Reflogs are useful in various Git commands, to specify the old value of a reference. For example, HEAD@{2} means "where HEAD used to be two moves ago", master@{one.week.ago} means "where master used to point to one week ago in this local repository", and so on. See gitrevisions(7) for more details.' }, { value: '--simplify-by-decoration', default_active: false, info: 'Allows you to view only the big picture of the topology of the history, by omitting commits that are not referenced by some branch or tag. Can be useful for very large repositories.' }],

			config_key: 'main-log',
			immediate: true,
		}
		let is_first_log_run = true
		/* Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
    This function exists so we can modify the args before sending to git, otherwise
    GitInput would have done the git call  */
		async function run_log(/** @type string */ log_args) {
			await store.git_run_log(log_args)
			await new Promise((ok) => setTimeout(ok, 0))
			if (is_first_log_run) {
				let first_selected_hash = selected_commits.value[0]?.hash
				if (first_selected_hash)
					scroll_to_commit_hash(first_selected_hash)
				is_first_log_run = false
			} else {
				if (selected_commit.value) {
					let new_commit = filtered_commits.value.find((commit) =>
						commit.hash === selected_commit.value?.hash)
					if (new_commit)
						selected_commits.value = [new_commit]
				}
				return commits_scroller_ref.value?.scrollToItem(scroll_item_offset)
			}
		}

		/** @type {Ref<any | null>} */
		let commits_scroller_ref = ref(null)
		/** @type {Ref<Commit[]>} */
		let visible_commits = ref([])
		let scroll_item_offset = 0
		function commits_scroller_updated(/** @type number */ start_index, /** @type number */ end_index) {
			scroll_item_offset = start_index
			let commits_start_index = scroll_item_offset < 3 ? 0 : scroll_item_offset
			visible_commits.value = filtered_commits.value.slice(commits_start_index, end_index)
		}
		function scroller_on_wheel(/** @type WheelEvent */ event) {
			if (store.config.value['disable-scroll-snapping'])
				return

			event.preventDefault()
			return commits_scroller_ref.value?.scrollToItem(scroll_item_offset + Math.round(event.deltaY / 20))
		}
		function scroller_on_keydown(/** @type KeyboardEvent */ event) {
			if (store.config.value['disable-scroll-snapping'])
				return

			if (event.key === 'ArrowDown') {
				event.preventDefault()
				return commits_scroller_ref.value?.scrollToItem(scroll_item_offset + 2)
			} else if (event.key === 'ArrowUp') {
				event.preventDefault()
				return commits_scroller_ref.value?.scrollToItem(scroll_item_offset - 2)
			}
		}
		function scroll_to_item_centered(/** @type number */ index) {
			return commits_scroller_ref.value?.scrollToItem(index - Math.floor(visible_commits.value.length / 2))
		}
		let scroll_item_height = computed(() =>
			store.config.value['row-height'])

		watch(visible_commits, async () => {
			let visible_cp = [...visible_commits.value].filter((commit) => // to avoid race conditions
				commit.hash && ! commit.stats)
			if (! visible_cp.length)
				return

			return await store.update_commit_stats(visible_cp)
		})
		let visible_branches = computed(() => [

			...new Set(visible_commits.value.flatMap((commit) => (commit.vis_lines || []).map((v) => v.branch))),
		].filter(is_truthy))
		let visible_branch_tips = computed(() => [

			...new Set(visible_commits.value.flatMap((commit) =>
				commit.refs)),
		].filter((ref) =>
		// @ts-ignore

			ref.type === 'branch' && ! ref.inferred))
		let invisible_branch_tips_of_visible_branches = computed(() =>
		// alternative: (visible_commits.value[0]?.refs.filter (ref) => ref.type == 'branch' and not ref.inferred and not visible_branch_tips.value.includes(ref)) or []

			visible_branches.value.filter((branch) =>
				(! branch.inferred || store.config.value['show-inferred-quick-branch-tips']) && ! visible_branch_tips.value.includes(branch)))

		// To paint a nice gradient between branches at the top and the vis below:

		let connection_fake_commit = computed(() => {
			let commit = visible_commits.value[0]
			if (! commit)
				return null; return {
				refs: [],

				vis_lines: commit.vis_lines.filter((line) => line.branch && invisible_branch_tips_of_visible_branches.value.includes(line.branch)).map((line) => ({
					...line,
					xn: line.x0,
					x0: line.x0 + ((line.xcs || 0) - line.x0) * -1,
					xcs: line.x0 + ((line.xcs || 0) - line.x0) * -1,
					xce: line.x0 + ((line.xcs || 0) - line.x0) * -3,
				})),
			}
		})
		// To show branch tips on top of connection_fake_commit lines

		let invisible_branch_tips_of_visible_branches_elems = computed(() => {
			let row = -1

			return [...connection_fake_commit.value?.vis_lines || []].reverse().map((line) => {
				if (! line.branch)
					return null
				row++
				if (row > 5)
					row = 0; return {
					branch: line.branch,
					bind: {
						style: {
							left: 0 + store.vis_v_width.value * line.x0 + 'px',
							top: 0 + row * 19 + 'px',
						},
					},
				}
			}).filter(is_truthy) || []
		})

		let global_actions = computed(() =>
			store.global_actions.value)

		onMounted(() => {
			// didn't work with @keyup.escape.native on the components root element

			// when focus was in a sub component (??) so doing this instaed:

			document.addEventListener('keyup', (e) => {
				if (e.key === 'Escape')
					selected_commits.value = []
			})
			return commits_scroller_ref.value.$el.focus()
		})

		// It didn't work with normal context binding to the scroller's commit elements, either a bug

		// of context-menu update or I misunderstood something about vue-virtual-scroller, but this

		// works around it reliably (albeit uglily)

		let commit_context_menu_provider = computed(() => (/** @type MouseEvent */ event) => {
			let el = event.target
			if (! (el instanceof HTMLElement) && ! (el instanceof SVGElement))
				return

			while (el.parentElement && ! el.parentElement.classList.contains('commit'))
				el = el.parentElement
			if (! el.parentElement)
				return

			let hash = el.parentElement.dataset.commitHash
			if (! hash)
				throw 'commit context menu element has no hash?'
			return store.commit_actions(hash).value.map((action) => ({
				label: action.title,
				icon: action.icon,
				action() {
					store.selected_git_action.value = action
				},
			}))
		})

		let config_show_quick_branch_tips = computed(() =>
			! store.config.value['hide-quick-branch-tips'])
		return {

			initialized,
			details_panel_position,
			filtered_commits,
			branches: store.branches,
			head_branch: store.head_branch,
			git_input_ref,
			run_log,
			log_action,
			commits_scroller_updated,
			commits_scroller_ref,
			scroll_to_branch_tip,
			scroll_to_commit_hash_user,
			scroll_to_top,
			selected_commit,
			selected_commits,
			commit_clicked,
			txt_filter,
			txt_filter_ref,
			txt_filter_type,
			txt_filter_enter,
			clear_filter,
			global_actions,
			combine_branches_to_branch_name: store.combine_branches_to_branch_name,
			combine_branches_from_branch_name: store.combine_branches_from_branch_name,
			combine_branches_actions: store.combine_branches_actions,
			invisible_branch_tips_of_visible_branches,
			invisible_branch_tips_of_visible_branches_elems,
			connection_fake_commit,
			refresh_main_view: store.refresh_main_view,
			selected_git_action: store.selected_git_action,
			commit_context_menu_provider,
			git_status: store.git_status,
			scroller_on_wheel,
			scroller_on_keydown,
			config_show_quick_branch_tips,
			scroll_item_height,
			txt_filter_regex,
		}
	},
}
