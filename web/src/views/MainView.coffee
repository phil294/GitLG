import store from '../store.coffee'
import colors from '../colors.coffee'
import * as log_utils from '../log-utils.coffee'
import { ref, computed } from 'vue'

export default
	setup: ->
		log_args = ref "log --graph --oneline --pretty=VSCode --author-date-order -n 15000 --skip=0 --all $(git reflog show --format='%h' stash)"
		log_error = ref ''
		commits = ref []
		# perhaps rename to branches? depending on what this actually shows some day
		branches = ref []
		show_invisible_branches = ref false
		vis_style = ref ''
		commits_scroller_ref = ref null
		scroll_pixel_buffer = 200 # 200 is also the default
		scroll_item_height = 18

		### Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git ###
		do_log = =>
			log_error.value = ''
			commits.value = []
			sep = '^%^%^%^%^'
			args = log_args.value.replace(" --pretty=VSCode", " --pretty=format:'#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s'")
			try
				data = await store.do_git args
			catch e
				console.warn e
				log_error.value = JSON.stringify e, null, 4
				return
			parsed = log_utils.parse data, sep
			color_by_branch = parsed.branches.reduce (all, branch, i) =>
				all[branch] = colors[i % (colors.length - 1)]
				all
			, {}
			commits.value = parsed.commits.map (c, i) => {
				...c
				i
				refs: c.refs.map (ref) =>
					name: ref
					style: color: color_by_branch[ref]
				datetime: if c.timestamp then new Date(c.timestamp).toISOString().slice(0,19).replace("T"," ") else undefined
				vis: c.vis.map (v) =>
					branch: v.branch # todo unify naming scheme obj vs name
					char: v.char
					style: color: color_by_branch[v.branch]
			}
			branches.value = parsed.branches
				.filter (branch) =>
					not branch.startsWith "virtual_branch_"
				.sort (a, b) =>
					a.indexOf("/") - b.indexOf("/") # todo this is messy, part here  part in log-utils
				.map (branch) =>
					name: branch
					style: color: color_by_branch[branch]
				.slice(0, 150)
			vis_style.value = 'min-width': "min(50vw, #{parsed.vis_max_length}em"
		
		do_log()

		commit_clicked = (commit) =>
			show_invisible_branches.value = false
			alert "clicked commit #{commit.subject}"

		visible_commits = ref []
		visible_commits_debouncer = 0
		commits_scroller_updated = (start_index, end_index) =>
			buffer_indices_amt = Math.floor(scroll_pixel_buffer / scroll_item_height) # those are invisible
			if start_index > 0
				start_index += buffer_indices_amt
			if end_index < commits.value.length - 1
				end_index -= buffer_indices_amt
			clearTimeout visible_commits_debouncer
			visible_commits_debouncer = setTimeout (=>
				visible_commits.value = commits.value.slice(start_index, end_index)
			), 170
		visible_branches = computed =>
			visible_branch_names = [...new Set(visible_commits.value
				.flatMap (commit) =>
					commit.vis.map (v) => v.branch)]
			branches.value.filter (branch) =>
				visible_branch_names.includes branch.name
		invisible_branches = computed =>
			branches.value.filter (branch) =>
				not visible_branches.value.includes branch
		
		scroll_to_branch_tip = (branch) =>
			first_branch_commit_i = commits.value.findIndex (commit) =>
				# Only applicable if virtual_branches excluded as these don't have a tip. Otherwise, vis would need to be traversed
				commit.refs.some (ref) => ref.name == branch.name
			if first_branch_commit_i == -1
				return store.show_error_message "No commit found for branch #{branch.name}. No idea why :/"
			commits_scroller_ref.value.scrollToItem first_branch_commit_i
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