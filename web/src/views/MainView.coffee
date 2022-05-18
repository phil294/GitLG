import { git, show_error_message } from '../store.coffee'
import { parse, Branch, Commit } from '../log-utils.coffee'
import { ref, Ref, computed, watch } from 'vue'

export default
	setup: ->
		log_args = ref "log --graph --oneline --pretty=VSCode --author-date-order -n 15000 --skip=0 --all $(git reflog show --format='%h' stash)"
		log_error = ref ''
		#
		###* @type {Ref<Commit[]>} ###
		commits = ref []
		#
		###* @type {Ref<Branch[]>} ###
		branches = ref []
		vis_style = ref {}

		### Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git ###
		do_log = =>
			log_error.value = ''
			commits.value = []
			sep = '^%^%^%^%^'
			args = log_args.value.replace(" --pretty=VSCode", " --pretty=format:'#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s'")
			try
				data = await git args
			catch e
				console.warn e
				log_error.value = JSON.stringify e, null, 4
				return
			parsed = parse data, sep
			commits.value = parsed.commits
			branches.value = parsed.branches
			vis_style.value = 'min-width': "min(50vw, #{parsed.vis_max_length}em"
		
		do_log()

		show_invisible_branches = ref false

		commit_clicked = (###* @type {Commit} ### commit) =>
			show_invisible_branches.value = false
			alert "clicked commit #{commit.subject}"

		scroll_pixel_buffer = 200 # 200 is also the default
		scroll_item_height = 18
		#
		###* @type {Ref<Commit[]>} ###
		visible_commits = ref []
		visible_commits_debouncer = 0
		commits_scroller_updated = (###* @type number ### start_index, ###* @type number ### end_index) =>
			buffer_indices_amt = Math.floor(scroll_pixel_buffer / scroll_item_height) # those are invisible
			if start_index > 0
				start_index += buffer_indices_amt
			if end_index < commits.value.length - 1
				end_index -= buffer_indices_amt
			window.clearTimeout visible_commits_debouncer
			visible_commits_debouncer = window.setTimeout (=>
				visible_commits.value = commits.value.slice(start_index, end_index)
			), 170

		visible_branches = computed =>
			[...new Set(visible_commits.value
				.flatMap (commit) =>
					commit.vis.map (v) => v.branch)]
			.filter(Boolean)
			.filter (branch) => not branch?.virtual
		invisible_branches = computed =>
			branches.value.filter (branch) =>
				not visible_branches.value.includes branch
		
		#
		###* @type {Ref<any | null>} ###
		commits_scroller_ref = ref null
		scroll_to_branch_tip = (###* @type Branch ### branch) =>
			first_branch_commit_i = commits.value.findIndex (commit) =>
				# Only applicable if virtual branches are excluded as these don't have a tip. Otherwise, each vis would need to be traversed
				commit.refs.some (ref) => ref.name == branch.name
			if first_branch_commit_i == -1
				return show_error_message "No commit found for branch #{branch.name}. No idea why :/"
			commits_scroller_ref.value?.scrollToItem first_branch_commit_i
			show_invisible_branches.value = false
		
		{
			commits
			branches # todo: if omitting this, no error is shown in webview, but in local serve it is??
			vis_style
			do_log
			log_args
			log_error
			commit_clicked
			commits_scroller_updated
			show_invisible_branches
			visible_branches
			invisible_branches
			commits_scroller_ref
			scroll_to_branch_tip
			scroll_pixel_buffer
			scroll_item_height
		}