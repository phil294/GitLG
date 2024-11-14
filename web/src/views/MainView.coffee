import { ref, computed, watch, nextTick, onMounted } from 'vue'
import * as store from './store.coffee'
import { show_error_message } from '../bridge.coffee'
import { is_truthy } from './types'
import GitInputModel from './GitInput.coffee'
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
###*
# @typedef {import('./types').Commit} Commit
# @typedef {import('./types').Branch} Branch
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###

export default
	components: { CommitDetails, CommitsDetails, GitInput, GitActionButton, AllBranches, RefTip, SelectedGitAction, RepoSelection, History, CommitRow }
	setup: ->
		###* @type {string[]} ###
		default_selected_commits_hashes = []
		selected_commits_hashes = store.stateful_computed 'repo:selected-commits-hashes', default_selected_commits_hashes
		selected_commits = computed
			get: =>
				(selected_commits_hashes.value
					?.map (hash) => filtered_commits.value.find (commit) => commit.full_hash == hash
					.filter is_truthy) or []
			set: (commits) =>
				selected_commits_hashes.value = commits.map (commit) => commit.full_hash
		selected_commit = computed =>
			if selected_commits.value.length == 1
				selected_commits.value[0]
		sticky_selected_commits = ref []
		selected_commits_from_sticky = ref []
		sticky_selected_commits_map = computed =>
			result_map = {}
			sticky_selected_commits.value.forEach (c) =>
				result_map[c.full_hash] = true
			return result_map
		selected_commits_from_sticky_map = computed =>
			result_map = {}
			selected_commits_from_sticky.value.forEach (c) =>
				result_map[c.full_hash] = true
			return result_map
		sticky_selected_commits_reverted = ref false
		watch(
			store.commits
			=>
				# console.log('store.commits', store.commits.value)
				sticky_selected_commits.value = []
		)
		commit_clicked = (###* @type Commit ### commit, ###* @type {MouseEvent | undefined} ### event) =>
			selected_commits_from_sticky.value = []
			return if not commit.full_hash
			selected_index = selected_commits.value.indexOf commit
			if event?.ctrlKey
				if selected_index > -1
					selected_commits.value = selected_commits.value.filter (_, i) => i != selected_index
				else
					selected_commits.value = [...selected_commits.value, commit]
			else if event?.shiftKey
				total_index = filtered_commits.value.indexOf commit
				last_total_index = filtered_commits.value.indexOf selected_commits.value[selected_commits.value.length-1]
				if total_index > last_total_index and total_index - last_total_index < 1000
					selected_commits.value = selected_commits.value.concat(filtered_commits.value.slice(last_total_index, total_index+1).filter (commit) =>
						not selected_commits.value.includes commit)
			else
				if selected_index > -1
					selected_commits.value = []
				else
					selected_commits.value = [commit]
					store.push_history type: 'commit_hash', value: commit.full_hash

		commit_sticky_selected = (###* @type Commit ### commit, ###* @type MouseEvent ### event) =>
			event.stopPropagation()
			return if not commit.full_hash
			if sticky_selected_commits.value.length > 0
				if sticky_selected_commits.value[0].full_hash == commit.full_hash
					if sticky_selected_commits_reverted.value
						sticky_selected_commits.value = []
					else
						sticky_selected_commits_reverted.value = true
				else
					selected_commits.value = if sticky_selected_commits_reverted.value then [commit, sticky_selected_commits.value[0]] else [sticky_selected_commits.value[0], commit]
					sticky_selected_commits.value = []
					selected_commits_from_sticky.value = selected_commits.value
			else
				selected_commits_from_sticky.value = []
				sticky_selected_commits.value = [commit]
				sticky_selected_commits_reverted.value = false



		txt_filter = ref ''
		###* @type {Ref<'filter' | 'jump' | 'jumphash'>} ###
		txt_filter_type = ref 'jumphash'
		clear_filter = =>
			txt_filter.value = ''
			if selected_commit.value
				selected_i = filtered_commits.value.findIndex (c) => c == selected_commit.value
				await nextTick()
				scroll_to_item_centered selected_i
		###* @type {Ref<HTMLElement | null>} ###
		txt_filter_ref = ref null
		txt_filter_filter = (###* @type Commit ### commit) =>
			search_for = txt_filter.value.toLowerCase().split(' ').map((x)=>x.trim()).filter((x) => x)

			remain_match_set = new Set
			curr_match_set = new Set
			for curr_word from search_for
				remain_match_set.add curr_word
			for str from [commit.subject, commit.full_hash, commit.author_name, commit.author_email, commit.branch?.id]
				str_lower = str?.toLowerCase()
				curr_match_set.clear()
				for curr_word from remain_match_set
					if str_lower?.includes(curr_word)
						curr_match_set.add curr_word
				remain_match_set = new Set([...remain_match_set].filter((x) => !curr_match_set.has(x)))
				if remain_match_set.size == 0
					break
			return remain_match_set.size == 0

		hash_filter = (###* @type Commit ### commit) =>
			search_for = txt_filter.value.toLowerCase()
			return true if commit.full_hash.startsWith(search_for)
		initialized = computed =>
			!! store.commits.value
		filtered_commits = computed =>
			if not txt_filter.value or txt_filter_type.value == 'jump' or txt_filter_type.value == 'jumphash'
				return store.commits.value or []
			(store.commits.value or []).filter txt_filter_filter
		txt_filter_last_i = -1
		document.addEventListener 'keyup', (e) =>
			if e.ctrlKey and e.key == 'f'
				txt_filter_ref.value?.focus()
		select_searched_commit_debouncer = -1
		txt_filter_enter = (###* @type KeyboardEvent ### event) =>
			return if txt_filter_type.value == 'filter'

			txt_filter_or_hash_filter = txt_filter_filter
			if txt_filter_type.value == 'jumphash'
				txt_filter_or_hash_filter = hash_filter

			if event.shiftKey
				next = [...filtered_commits.value.slice(0, txt_filter_last_i)].reverse().findIndex(txt_filter_or_hash_filter)
				if next > -1
					next_match_index = txt_filter_last_i - 1 - next
				else
					next = filtered_commits.value.reverse().findIndex(txt_filter_or_hash_filter)
					if next > -1
						next_match_index = filtered_commits.value.length - 1 - next
					else
						next_match_index = -1
			else
				next = filtered_commits.value.slice(txt_filter_last_i + 1).findIndex(txt_filter_or_hash_filter)
				if next > -1
					next_match_index = txt_filter_last_i + 1 + next
				else
					next = filtered_commits.value.findIndex(txt_filter_or_hash_filter)
					if next > -1
						next_match_index = next
					else
						next_match_index = -1
			if next_match_index == -1
				show_error_message 'Can\'t find commit' + (if txt_filter_type.value == 'jumphash' then ' with hash ' else ' that matches ') + txt_filter.value + '.'
				return

			scroll_to_item_centered next_match_index
			txt_filter_last_i = next_match_index
			window.clearTimeout select_searched_commit_debouncer
			select_searched_commit_debouncer = window.setTimeout (=>
				selected_commits.value = [filtered_commits.value[txt_filter_last_i]]
			), 100
		watch txt_filter, =>
			if txt_filter.value
				store.push_history type: 'txt_filter', value: txt_filter.value



		scroll_to_branch_tip = (###* @type Branch ### branch) =>
			first_branch_commit_i = filtered_commits.value.findIndex (commit) =>
				if branch.inferred
					commit.vis_lines.some (vis_line) => vis_line.branch == branch
				else
					commit.refs.some (ref) => ref == branch
			if first_branch_commit_i == -1
				return show_error_message "No commit found for branch #{branch.id}. Not enough commits loaded?"
			if branch.inferred
				# We want to go the the actual merge commit, not the first any-commit where
				# this line appeared (could be entirely unrelated)
				first_branch_commit_i--
			scroll_to_item_centered first_branch_commit_i
			commit = filtered_commits.value[first_branch_commit_i]
			# Not only scroll to tip, but also select it, so the behavior is equal to clicking on
			# a branch name in a commit's ref list.
			selected_commits.value = [commit]
			# For now, set history always to commit_hash as this also shows the branches. Might revisit some day TODO
			# if branch.inferred
			# 	store.push_history type: 'commit_hash', value: commit.full_hash
			# else
			# 	store.push_history type: 'branch_id', value: branch.id
			store.push_history type: 'commit_hash', value: commit.full_hash
		scroll_to_commit = (###* @type string ### hash) =>
			commit_i = filtered_commits.value.findIndex (commit) =>
				commit.full_hash == hash
			if commit_i == -1
				return show_error_message "No commit found for hash #{hash}. No idea why :/"
			scroll_to_item_centered commit_i
			selected_commits.value = [filtered_commits.value[commit_i]]
		scroll_to_commit_user = (###* @type string ### full_hash) =>
			scroll_to_commit full_hash
			store.push_history type: 'commit_hash', value: full_hash
		scroll_to_top = =>
			commits_scroller_ref.value?.scrollToItem 0



		###* @type {Ref<GitInputModel | null>} ###
		git_input_ref = ref null
		store.main_view_git_input_ref.value = git_input_ref
		all_branches_ref = ref null
		store.main_view_all_branches_ref.value = all_branches_ref
		log_action =
			# rearding the -greps: Under normal circumstances, when showing stashes in
			# git log, each of the stashes 2 or 3 parents are being shown. That because of
			# git internals, but they are completely useless to the user.
			# Could not find any easy way to skip those other than de-grepping them, TODO:.
			# Something like `--exclude-commit=stash@{...}^2+` doesn't exist.
			args: "log --graph --oneline --date=iso-local --pretty={EXT_FORMAT} -n 15000 --skip=0 --all {STASH_REFS} --color=never --invert-grep --extended-regexp --grep=\"^untracked files on \" --grep=\"^index on \""
			options: [
				{ value: '--decorate-refs-exclude=refs/remotes', default_active: false, info: 'Hide remote branches' }
				{ value: '--grep="^Merge (remote[ -]tracking )?(branch \'|pull request #)"', default_active: false, info: 'Hide merge commits' }
				{ value: '--date-order', default_active: true, info: 'Show no parents before all of its children are shown, but otherwise show commits in the commit timestamp order.' }
				{ value: '--author-date-order', default_active: false, info: 'Show no parents before all of its children are shown, but otherwise show commits in the author timestamp order.' }
				{ value: '--topo-order', default_active: false, info: 'Show no parents before all of its children are shown, and avoid showing commits on multiple lines of history intermixed.' }
				{ value: '--reflog', default_active: false, info: 'Pretend as if all objects mentioned by reflogs are listed on the command line as <commit>. / Reference logs, or "reflogs", record when the tips of branches and other references were updated in the local repository. Reflogs are useful in various Git commands, to specify the old value of a reference. For example, HEAD@{2} means "where HEAD used to be two moves ago", master@{one.week.ago} means "where master used to point to one week ago in this local repository", and so on. See gitrevisions(7) for more details.' }
				{ value: '--simplify-by-decoration', default_active: false, info: 'Allows you to view only the big picture of the topology of the history, by omitting commits that are not referenced by some branch or tag. Can be useful for very large repositories.' }

			]
			config_key: "main-log"
			immediate: true
		is_first_log_run = true
		### Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
		This function exists so we can modify the args before sending to git, otherwise
		GitInput would have done the git call ###
		run_log = (###* @type string ### log_args) =>
			await store.git_run_log(log_args)
			await new Promise (ok) => setTimeout(ok, 0)
			if is_first_log_run
				first_selected_hash = selected_commits.value[0]?.full_hash
				if first_selected_hash
					scroll_to_commit first_selected_hash
				is_first_log_run = false
			else
				if selected_commit.value
					new_commit = filtered_commits.value.find (commit) =>
						commit.full_hash == selected_commit.value?.full_hash
					if new_commit
						selected_commits.value = [new_commit]
				commits_scroller_ref.value?.scrollToItem scroll_item_offset




		###* @type {Ref<any | null>} ###
		commits_scroller_ref = ref null
		###* @type {Ref<Commit[]>} ###
		visible_commits = ref []
		scroll_item_offset = 0
		commits_scroller_updated = (###* @type number ### start_index, ###* @type number ### end_index) =>
			scroll_item_offset = start_index
			commits_start_index = if scroll_item_offset < 3 then 0 else scroll_item_offset
			visible_commits.value = filtered_commits.value.slice(commits_start_index, end_index)
		scroller_on_wheel = (###* @type WheelEvent ### event) =>
			return if store.config.value['disable-scroll-snapping']
			event.preventDefault()
			commits_scroller_ref.value?.scrollToItem scroll_item_offset + Math.round(event.deltaY / 20)
		scroller_on_keydown = (###* @type KeyboardEvent ### event) =>
			return if store.config.value['disable-scroll-snapping']
			if event.key == 'ArrowDown'
				event.preventDefault()
				commits_scroller_ref.value?.scrollToItem scroll_item_offset + 2
			else if event.key == 'ArrowUp'
				event.preventDefault()
				commits_scroller_ref.value?.scrollToItem scroll_item_offset - 2
		scroll_to_item_centered = (###* @type number ### index) =>
			commits_scroller_ref.value?.scrollToItem index - Math.floor(visible_commits.value.length / 2)
		temporary_view_commit_only = () =>
			store.temporary_view_commit_only(selected_commit.value)
		scroll_item_height = computed =>
			store.config.value['row-height']




		watch visible_commits, =>
			visible_cp = [...visible_commits.value] # to avoid race conditions
				.filter (commit) => commit.full_hash and not commit.stats
			if not visible_cp.length then return
			await store.update_commit_stats(visible_cp)
		visible_branches = computed =>
			[...new Set(visible_commits.value
				.flatMap (commit) =>
					(commit.vis_lines || []).map (v) => v.branch)]
			.filter(is_truthy)
		visible_branch_tips = computed =>
			[...new Set(visible_commits.value
				.flatMap (commit) =>
					commit.refs)]
			.filter (ref) =>
				# @ts-ignore
				ref.type == 'branch' and not ref.inferred
		invisible_branch_tips_of_visible_branches = computed =>
			# alternative: (visible_commits.value[0]?.refs.filter (ref) => ref.type == 'branch' and not ref.inferred and not visible_branch_tips.value.includes(ref)) or []
			visible_branches.value.filter (branch) =>
				(! branch.inferred || store.config.value['show-inferred-quick-branch-tips']) &&
				not visible_branch_tips.value.includes branch




		# To paint a nice gradient between branches at the top and the vis below:
		connection_fake_commit = computed =>
			commit = visible_commits.value[0]
			return null if not commit
			refs: []
			vis_lines: commit.vis_lines
				.filter (line) =>
					line.branch && invisible_branch_tips_of_visible_branches.value.includes(line.branch)
				.map (line) => {
					...line
					xn: line.x0
					x0: line.x0 + ((line.xcs || 0) - line.x0) * (-1)
					xcs: line.x0 + ((line.xcs || 0) - line.x0) * (-1)
					xce: line.x0 + ((line.xcs || 0) - line.x0) * (-3)
				}
		# To show branch tips on top of connection_fake_commit lines
		invisible_branch_tips_of_visible_branches_elems = computed =>
			row = -1
			([...(connection_fake_commit.value?.vis_lines || [])].reverse()
				.map (line) =>
					return null if not line.branch
					row++
					row = 0 if row > 5
					branch: line.branch
					bind:
						style:
							left: 0 + store.vis_v_width.value * line.x0 + 'px'
							top: 0 + row * 19 + 'px'
				.filter(is_truthy)) or []



		global_actions = computed =>
			store.global_actions.value



		onMounted =>
			# didn't work with @keyup.escape.native on the components root element
			# when focus was in a sub component (??) so doing this instaed:
			document.addEventListener 'keyup', (e) =>
				if e.key == "Escape"
					selected_commits.value = []
			commits_scroller_ref.value.$el.focus()


		# It didn't work with normal context binding to the scroller's commit elements, either a bug
		# of context-menu update or I misunderstood something about vue-virtual-scroller, but this
		# works around it reliably (albeit uglily)
		commit_context_menu_provider = computed => (###* @type MouseEvent ### event) =>
			el = event.target
			return if el not instanceof HTMLElement and el not instanceof SVGElement
			while el.parentElement and not el.parentElement.classList.contains('commit')
				el = el.parentElement
			return if not el.parentElement
			hash = el.parentElement.dataset.commitHash
			throw "commit context menu element has no hash?" if not hash
			store.commit_actions(hash).value.map (action) =>
				label: action.title
				icon: action.icon
				action: =>
					store.selected_git_action.value = action



		config_show_quick_branch_tips = computed =>
			not store.config.value['hide-quick-branch-tips']



		{
			initialized
			filtered_commits
			branches: store.branches
			head_branch: store.head_branch
			git_input_ref
			all_branches_ref
			run_log
			log_action
			commits_scroller_updated
			commits_scroller_ref
			scroll_to_branch_tip
			scroll_to_commit_user
			scroll_to_top
			selected_commit
			selected_commits
			sticky_selected_commits
			sticky_selected_commits_map
			selected_commits_from_sticky
			selected_commits_from_sticky_map
			sticky_selected_commits_reverted
			commit_clicked
			commit_sticky_selected
			txt_filter
			txt_filter_ref
			txt_filter_type
			txt_filter_enter
			clear_filter
			global_actions
			combine_branches_to_branch_name: store.combine_branches_to_branch_name
			combine_branches_from_branch_name: store.combine_branches_from_branch_name
			combine_branches_actions: store.combine_branches_actions
			invisible_branch_tips_of_visible_branches
			invisible_branch_tips_of_visible_branches_elems
			connection_fake_commit
			refresh_main_view: store.refresh_main_view
			go_to_head: store.go_to_head
			selected_git_action: store.selected_git_action
			reset_command: store.reset_command
			temporary_view_commit_only: temporary_view_commit_only
			commit_context_menu_provider
			git_status: store.git_status
			scroller_on_wheel
			scroller_on_keydown
			config_show_quick_branch_tips
			scroll_item_height
		}