import { git, show_error_message, get_config } from '../bridge.coffee'
# TODO: type errors
import { parse, Branch, Commit } from './log-utils.coffee'
import { ref, Ref, computed, watch } from 'vue'
import GitInputModel, { parse_config_actions, GitAction } from './GitInput.coffee'
import GitInput from './GitInput.vue'
import GitActionButton from './GitActionButton.vue'
import SelectedCommit from './SelectedCommit.vue'
import Visualization from './Visualization.vue'

export default
	components: { SelectedCommit, GitInput, GitActionButton, Visualization }
	setup: ->
		``###* @type {Ref<Branch[]>} ###
		branches = ref []
		# this is either a branch name or HEAD in which case it will simply not be shown
		# which is also not necessary because HEAD is then also visible as a branch tip.
		head_branch = ref ''
		vis_max_length = ref 0
		``###* @type {Ref<Commit | null>} ###
		selected_commit = ref null
		``###* @type {Ref<GitInputModel | null>} ###
		git_input_ref = ref null
		``###* @type {Ref<any | null>} ###
		commits_scroller_ref = ref null

		do_log = =>
			git_input_ref.value?.execute()

		``###* @type {Ref<Commit[]>} ###
		returned_commits = ref []
		txt_filter = ref ''
		``###* @type {Ref<'filter' | 'search'>} ###
		txt_filter_type = ref 'filter'
		# TODO: error here somewhere
		clear_filter = =>
			txt_filter.value = ''
			if selected_commit.value
				selected_i = commits.value.findIndex (c) => c == selected_commit.value
				commits_scroller_ref.value?.scrollToItem selected_i - Math.floor(visible_commits.value.length / 2) + 2
		``###* @type {Ref<HTMLElement | null>} ###
		txt_filter_ref = ref null
		txt_filter_filter = (###* @type Commit ### commit) =>
			search_for = txt_filter.value.toLowerCase()
			for str from [commit.subject, commit.hash, commit.author_name, commit.author_email, commit.branch?.name]
				return true if str?.includes(search_for)
		commits = computed =>
			if not txt_filter.value or txt_filter_type.value == 'search'
				return returned_commits.value
			returned_commits.value.filter txt_filter_filter
		txt_filter_last_i = -1
		document.addEventListener 'keyup', (e) =>
			if e.ctrlKey and e.key == 'f'
				txt_filter_ref.value?.focus()
		select_searched_commit_debouncer = -1
		txt_filter_enter = (###* @type KeyboardEvent ### event) =>
			return if txt_filter_type.value == 'filter'
			if event.shiftKey
				next = [...commits.value.slice(0, txt_filter_last_i)].reverse().findIndex(txt_filter_filter)
				if next > -1
					next_match_index = txt_filter_last_i - 1 - next
				else
					next_match_index = commits.value.length - 1
			else
				next = commits.value.slice(txt_filter_last_i + 1).findIndex(txt_filter_filter)
				if next > -1
					next_match_index = txt_filter_last_i + 1 + next
				else
					next_match_index = 0
			commits_scroller_ref.value?.scrollToItem next_match_index - Math.floor(visible_commits.value.length / 2) + 2
			txt_filter_last_i = next_match_index
			window.clearTimeout select_searched_commit_debouncer
			select_searched_commit_debouncer = window.setTimeout (=>
				selected_commit.value = commits.value[txt_filter_last_i]
			), 100

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
			sep = '^%^%^%^%^'
			log_args = log_args.replace(" --pretty=VSCode", " --pretty=format:\"#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s\"")
			stash_refs = try await git 'reflog show --format="%h" stash' catch then ""
			log_args = log_args.replace("stash_refs", stash_refs.replaceAll('\n', ' '))
			# errors will be handled by GitInput
			[ log_data, stash_data ] = await Promise.all [
				git log_args
				try await git 'stash list --format="%h %gd"'
			]
			return if not log_data
			parsed = parse log_data, sep
			# stashes are queried (git reflog show stash) but shown as commits. Need to add refs:
			for stash from (stash_data or '').split('\n')
				# 7c37db63 stash@{11}
				split = stash.split(' ')
				parsed.commits.find((c) => c.hash == split[0])?.refs.push
					name: split.slice(1).join(' ')
					type: "stash"
					color: '#fff'
			returned_commits.value = parsed.commits
			branches.value = parsed.branches
			vis_max_length.value = parsed.vis_max_length
			if selected_commit.value
				selected_commit.value = (commits.value.find (commit) =>
					commit.hash == selected_commit.value?.hash) or null
			await new Promise (ok) => setTimeout(ok, 0)
			commits_scroller_ref.value?.scrollToItem scroll_item_offset.value
			head_branch.value = await git 'rev-parse --abbrev-ref HEAD'
		
		show_invisible_branches = ref false

		``###* @type {Ref<Commit[]>} ###
		visible_commits = ref []
		scroll_item_offset = ref 0
		visible_commits_debouncer = 0
		commits_scroller_updated = (###* @type number ### start_index, ###* @type number ### end_index) =>
			scroll_item_offset.value = start_index
			window.clearTimeout visible_commits_debouncer
			visible_commits_debouncer = window.setTimeout (=>
				visible_commits.value = commits.value.slice(start_index, end_index)
			), 170
		
		watch visible_commits, =>
			visible_cp = [...visible_commits.value] # to avoid race conditions
				.filter (commit) => commit.hash and not commit.stats
			if not visible_cp.length then return
			data = await git "show --format=\"%h\" --shortstat " + visible_cp.map((c)=>c.hash).join(' ')
			return if not data
			hash = ''
			for line from data.split('\n').filter(Boolean)
				if not line.startsWith ' '
					hash = line
					continue
				stat = files_changed: 0, insertions: 0, deletions: 0
				#  3 files changed, 87 insertions(+), 70 deletions(-)
				for stmt from line.trim().split(', ')
					words = stmt.split(' ')
					if words[1].startsWith 'file'
						stat.files_changed = Number(words[0])
					else if words[1].startsWith 'insertion'
						stat.insertions = Number(words[0])
					else if words[1].startsWith 'deletion'
						stat.deletions = Number(words[0])
				visible_cp[visible_cp.findIndex((cp)=>cp.hash==hash)].stats = stat


		visible_branches = computed =>
			[...new Set(visible_commits.value
				.flatMap (commit) =>
					commit.vis.map (v) => v.branch)]
			.filter(Boolean)
			.filter (branch) => not branch?.virtual
		invisible_branches = computed =>
			branches.value.filter (branch) =>
				not visible_branches.value.includes branch

		scroll_to_branch_tip = (###* @type string ### branch_name) =>
			first_branch_commit_i = commits.value.findIndex (commit) =>
				# Only applicable if virtual branches are excluded as these don't have a tip. Otherwise, each vis would need to be traversed
				commit.refs.some (ref) => ref.name == branch_name
			if first_branch_commit_i == -1
				return show_error_message "No commit found for branch #{branch_name}. No idea why :/"
			commits_scroller_ref.value?.scrollToItem first_branch_commit_i
			show_invisible_branches.value = false
			# Not only scroll to tip, but also select it, so the behavior is equal to clicking on
			# a branch name in a commit's ref list.
			selected_commit.value = commits.value[first_branch_commit_i]
		
		commit_clicked = (###* @type {Commit} ### commit) =>
			show_invisible_branches.value = false
			selected_commit.value =
				if selected_commit.value == commit
					null
				else
					commit

		config_global_actions = ref []
		do =>
			config_global_actions.value = await get_config 'actions.global'
		global_actions = computed => parse_config_actions config_global_actions.value
		
		drag_drop_target_branch_name = ref ''
		drag_drop_source_branch_name = ref ''
		``###*
		# @param target_branch_name {string}
		# @param options {import('@web/directives/drop').DropCallbackPayload}
		###
		branch_drop = (target_branch_name, { data: source_branch_name }) =>
			return if typeof source_branch_name != 'string' or source_branch_name == target_branch_name
			drag_drop_target_branch_name.value = target_branch_name
			drag_drop_source_branch_name.value = source_branch_name
		config_drag_drop_branch_actions = ref []
		do =>
			config_drag_drop_branch_actions.value = await get_config 'actions.branch-drop'
		drag_drop_branch_actions = computed => parse_config_actions config_drag_drop_branch_actions.value, [['{SOURCE_BRANCH_NAME}', drag_drop_source_branch_name.value], ['{TARGET_BRANCH_NAME}', drag_drop_target_branch_name.value]]

		{
			commits
			branches
			vis_max_length
			head_branch
			git_input_ref
			run_log
			do_log
			log_action
			commit_clicked
			commits_scroller_updated
			show_invisible_branches
			visible_branches
			invisible_branches
			commits_scroller_ref
			scroll_to_branch_tip
			selected_commit
			txt_filter
			txt_filter_ref
			txt_filter_type
			txt_filter_enter
			clear_filter
			global_actions
			branch_drop
			drag_drop_target_branch_name
			drag_drop_source_branch_name
			drag_drop_branch_actions
		}