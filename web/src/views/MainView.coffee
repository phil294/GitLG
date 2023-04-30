import * as store from './store.coffee'
import { show_error_message } from '../bridge.coffee'
import { ref, computed, watch } from 'vue'
import GitInputModel from './GitInput.coffee'
import GitInput from './GitInput.vue'
import GitActionButton from './GitActionButton.vue'
import SelectedCommit from './SelectedCommit.vue'
import Visualization from './Visualization.vue'
import AllBranches from './AllBranches.vue'
import RefTip from './RefTip.vue'
``###*
# @typedef {import('./types').Commit} Commit
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###
###* @template T @typedef {import('vue').ComputedRef<T>} ComputedRef ###

``###*
# To use in place of `.filter(Boolean)` for type safety with strict null checks.
# @template T
# @param value {T | undefined | null | false}
# @return {value is T}
###
is_truthy = (value) => !!value

export default
	components: { SelectedCommit, GitInput, GitActionButton, Visualization, AllBranches, RefTip }
	setup: ->
		``###* @type {Ref<Commit | null>} ###
		selected_commit = ref null
		commit_clicked = (###* @type {Commit} ### commit) =>
			selected_commit.value =
				if selected_commit.value == commit
					null
				else
					commit




		txt_filter = ref ''
		``###* @type {Ref<'filter' | 'search'>} ###
		txt_filter_type = ref 'filter'
		clear_filter = =>
			txt_filter.value = ''
			if selected_commit.value
				selected_i = filtered_commits.value.findIndex (c) => c == selected_commit.value
				commits_scroller_ref.value?.scrollToItem selected_i - Math.floor(visible_commits.value.length / 2) + 2
		``###* @type {Ref<HTMLElement | null>} ###
		txt_filter_ref = ref null
		txt_filter_filter = (###* @type Commit ### commit) =>
			search_for = txt_filter.value.toLowerCase()
			for str from [commit.subject, commit.hash, commit.author_name, commit.author_email, commit.branch?.name]
				return true if str?.includes(search_for)
		filtered_commits = computed =>
			if not txt_filter.value or txt_filter_type.value == 'search'
				return store.commits.value
			store.commits.value.filter txt_filter_filter
		txt_filter_last_i = -1
		document.addEventListener 'keyup', (e) =>
			if e.ctrlKey and e.key == 'f'
				txt_filter_ref.value?.focus()
		select_searched_commit_debouncer = -1
		txt_filter_enter = (###* @type KeyboardEvent ### event) =>
			return if txt_filter_type.value == 'filter'
			if event.shiftKey
				next = [...filtered_commits.value.slice(0, txt_filter_last_i)].reverse().findIndex(txt_filter_filter)
				if next > -1
					next_match_index = txt_filter_last_i - 1 - next
				else
					next_match_index = filtered_commits.value.length - 1
			else
				next = filtered_commits.value.slice(txt_filter_last_i + 1).findIndex(txt_filter_filter)
				if next > -1
					next_match_index = txt_filter_last_i + 1 + next
				else
					next_match_index = 0
			commits_scroller_ref.value?.scrollToItem next_match_index - Math.floor(visible_commits.value.length / 2) + 2
			txt_filter_last_i = next_match_index
			window.clearTimeout select_searched_commit_debouncer
			select_searched_commit_debouncer = window.setTimeout (=>
				selected_commit.value = filtered_commits.value[txt_filter_last_i]
			), 100



		scroll_to_branch_tip = (###* @type string ### branch_name) =>
			first_branch_commit_i = filtered_commits.value.findIndex (commit) =>
				# Only applicable if virtual branches are excluded as these don't have a tip. Otherwise, each vis would need to be traversed
				commit.refs.some (ref) => ref.name == branch_name
			if first_branch_commit_i == -1
				return show_error_message "No commit found for branch #{branch_name}. No idea why :/"
			commits_scroller_ref.value?.scrollToItem first_branch_commit_i
			# Not only scroll to tip, but also select it, so the behavior is equal to clicking on
			# a branch name in a commit's ref list.
			selected_commit.value = filtered_commits.value[first_branch_commit_i]




		``###* @type {Ref<GitInputModel | null>} ###
		git_input_ref = ref null
		do_log = =>
			git_input_ref.value?.execute()
		log_action =
			# rearding the -greps: Under normal circumstances, when showing stashes in
			# git log, each of the stashes 2 or 3 parents are being shown. That because of
			# git internals, but they are completely useless to the user.
			# Could not find any easy way to skip those other than de-grepping them, TODO:.
			# Something like `--exclude-commit=stash@{...}^2+` doesn't exist.
			args: "log --graph --oneline --pretty=VSCode --author-date-order -n 15000 --skip=0 --all stash_refs --invert-grep --grep=\"^untracked files on \" --grep=\"^index on \""
			options: [ { value: '--reflog', default_active: false } ]
			config_key: "main-log"
			immediate: true
		### Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
		This function exists so we can modify the args before sending to git, otherwise
		GitInput would have done the git call ###
		run_log = (###* @type string ### log_args) =>
			await store.git_run_log(log_args)
			if selected_commit.value
				selected_commit.value = (filtered_commits.value.find (commit) =>
					commit.hash == selected_commit.value?.hash) or null
			await new Promise (ok) => setTimeout(ok, 0)
			commits_scroller_ref.value?.scrollToItem scroll_item_offset
		



		``###* @type {Ref<any | null>} ###
		commits_scroller_ref = ref null
		``###* @type {Ref<Commit[]>} ###
		visible_commits = ref []
		scroll_item_offset = 0
		scroll_item_offset_end = 0
		scroll_callback_debouncer = 0
		scroll_callback_debouncer2 = 0
		ignore_next_scroll_event = false
		commits_scroller_updated = (###* @type number ### start_index, ###* @type number ### end_index) =>
			if ignore_next_scroll_event
				ignore_next_scroll_event = false
				return
			# https://github.com/Akryum/vue-virtual-scroller/issues/801
			new_scroll_item_offset = if start_index > 0 then Math.max(3, start_index + 1) else 0
			if new_scroll_item_offset != scroll_item_offset
				scroll_item_offset = new_scroll_item_offset
				scroll_item_offset_end = end_index
				window.clearTimeout scroll_callback_debouncer
				scroll_callback_debouncer = window.setTimeout scroll_callback, 80
		scroll_callback = =>
			visible_commits.value = filtered_commits.value.slice(scroll_item_offset, scroll_item_offset_end)
			if not ignore_next_scroll_event
				window.clearTimeout scroll_callback_debouncer2
				scroll_callback_debouncer2 = window.setTimeout(=>
					ignore_next_scroll_event = true
					# We'll have to do it once again after a greater delay because
					# somehow sometimes there's more scrolling going on *after* updated callback.
					# This strategy seems to be reliable contrary to also listening to @scroll event.
					scroll_callback()
				, 500)
			ignore_next_scroll_event = true
			# Snap-scroll to the item - see link above. We do this so we don't show half rows
			# so the connection fake commit always fits properly
			commits_scroller_ref.value?.scrollToItem scroll_item_offset



		watch visible_commits, =>
			visible_cp = [...visible_commits.value] # to avoid race conditions
				.filter (commit) => commit.hash and not commit.stats
			if not visible_cp.length then return
			await store.update_commit_stats(visible_cp)
		visible_branches = computed =>
			[...new Set(visible_commits.value
				.flatMap (commit) =>
					commit.vis.map (v) => v.branch)]
			.filter(is_truthy)
			.filter (branch) => not branch.virtual
		visible_branch_tips = computed =>
			[...new Set(visible_commits.value
				.flatMap (commit) =>
					commit.refs)]
			.filter (ref) =>
				# @ts-ignore
				ref.type == 'branch' and not ref.virtual
		invisible_branch_tips_of_visible_branches = computed =>
			# alternative: (visible_commits.value[0]?.refs.filter (ref) => ref.type == 'branch' and not ref.virtual and not visible_branch_tips.value.includes(ref)) or []
			visible_branches.value.filter (branch) =>
				not visible_branch_tips.value.includes branch

		


		# To paint a nice gradient between branches at the top and the vis below:
		connection_fake_commit = computed =>
			commit = visible_commits.value[0]
			return null if not commit
			{
				...commit
				scroll_height: 100
				refs: []
				vis: commit.vis.map (v) => {
					...v
					char:
						if v.branch and invisible_branch_tips_of_visible_branches.value.includes(v.branch)
							switch v.char
								when '*', '|', '⎽*', '⎽|', '*⎽', '|⎽' then '|'
								when '⎺*', '⎺|', '\\', '_', '.', '-'  then '⎽|'
								when '*⎺', '|⎺', '/'                  then '|⎽'
								when '⎺\\', '⎺\\⎽'                    then '⎽⎽|'
								when '/⎺'                             then '|⎽⎽'
						else ' '
				}
			}
		invisible_branch_tips_of_visible_branches_elems = computed =>
			v_width = 10 # TODO sync
			row = -1
			connection_fake_commit.value?.vis
				.map (v, i) =>
					return null if not v.branch or v.char == ' '
					row++
					row = 0 if row > 5
					branch: v.branch
					bind:
						style:
							left: 0 + v_width * i + 'px'
							top: 0 + row * 19 + 'px'
				.filter(is_truthy)



		
		global_actions = computed =>
			store.global_actions.value
		


		
		{
			filtered_commits
			branches: store.branches
			vis_max_length: store.vis_max_length
			head_branch: store.head_branch
			git_input_ref
			run_log
			do_log
			log_action
			commit_clicked
			commits_scroller_updated
			visible_branches
			commits_scroller_ref
			scroll_to_branch_tip
			selected_commit
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
		}