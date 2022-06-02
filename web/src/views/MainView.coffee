import { git, show_error_message } from '../store.coffee'
import { parse, Branch, Commit } from '../log-utils.coffee'
import { ref, Ref, computed, watch } from 'vue'
import SelectedCommit from './SelectedCommit.vue'
import GitInput from './GitInput.vue'
import GitInputModel from './GitInput.coffee'

export default
	components: { SelectedCommit, GitInput }
	setup: ->
		``###* @type {Ref<Branch[]>} ###
		branches = ref []
		# this is either a branch name or HEAD in which case it will simply not be shown
		# which is also not necessary because HEAD is then also visible as a branch tip.
		head_branch = ref ''
		vis_style = ref {}
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
		``###* @type {Ref<string | null>} ###
		txt_filter = ref null
		``###* @type {Ref<HTMLElement | null>} ###
		txt_filter_ref = ref null
		commits = computed =>
			if txt_filter.value == null
				return returned_commits.value
			returned_commits.value.filter (commit) =>
				["subject", "hash", "author_name", "author_email"].some (prop) =>
					#@ts-ignore
					commit[prop].toLowerCase().includes(txt_filter.value?.toLowerCase())
		document.addEventListener 'keyup', (e) =>
			if e.ctrlKey and e.key == 'f'
				if txt_filter.value == null
					txt_filter.value = ''
					await new Promise (ok) => setTimeout(ok, 0)
					txt_filter_ref.value?.focus()
				else
					txt_filter.value = null

		### Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
		This function exists so we can modify the args before sending to git, otherwise
		GitInput would have done the git call ###
		run_log = (###* @type string ### args) =>
			sep = '^%^%^%^%^'
			args = args.replace(" --pretty=VSCode", " --pretty=format:'#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s'")
			data = await git args # error will be handled by GitInput
			return if not data
			parsed = parse data, sep
			first_visible_commit_i = commits.value.indexOf(visible_commits.value[0])
			returned_commits.value = parsed.commits
			branches.value = parsed.branches
			vis_style.value = 'min-width': "min(50vw, #{parsed.vis_max_length/2}em)"
			if selected_commit.value
				selected_commit.value = (commits.value.find (commit) =>
					commit.hash == selected_commit.value?.hash) or null
			await new Promise (ok) => setTimeout(ok, 0)
			commits_scroller_ref.value?.scrollToItem first_visible_commit_i
			head_branch.value = await git 'rev-parse --abbrev-ref HEAD'
		
		mousemove_debouncer = -1
		hover_branch_debouncer = -1
		``###* @type {Ref<string | null>} ###
		hovered_branch_name = ref null
		document.addEventListener 'mousemove', (e) =>
			window.clearTimeout mousemove_debouncer
			mousemove_debouncer = window.setTimeout (=>
				if e.target?.classList.contains('vis-v')
					if branch_name = e.target.dataset.branchName
						hovered_branch_name.value = branch_name
						window.clearTimeout hover_branch_debouncer
						hover_branch_debouncer = window.setTimeout (=>
							hovered_branch_name.value = null
						), 300
			), 100


		show_invisible_branches = ref false

		scroll_pixel_buffer = 200 # 200 is also the default
		scroll_item_height = 22 # must be synced with css (v-bind doesn't work with coffee)
		``###* @type {Ref<Commit[]>} ###
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

		watch visible_commits, =>
			visible_cp = [...visible_commits.value] # to avoid race conditions
				.filter (commit) => commit.hash and not commit.stats
			if not visible_cp.length then return
			data = await git "show --format='%h' --shortstat " + visible_cp.map((c)=>c.hash).join(' ')
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

		scroll_to_branch_tip = (###* @type Branch ### branch) =>
			first_branch_commit_i = commits.value.findIndex (commit) =>
				# Only applicable if virtual branches are excluded as these don't have a tip. Otherwise, each vis would need to be traversed
				commit.refs.some (ref) => ref.name == branch.name
			if first_branch_commit_i == -1
				return show_error_message "No commit found for branch #{branch.name}. No idea why :/"
			commits_scroller_ref.value?.scrollToItem first_branch_commit_i
			show_invisible_branches.value = false
		
		commit_clicked = (###* @type {Commit} ### commit) =>
			show_invisible_branches.value = false
			selected_commit.value = commit
		
		{
			commits
			branches
			vis_style
			head_branch
			git_input_ref
			run_log
			do_log
			commit_clicked
			commits_scroller_updated
			show_invisible_branches
			visible_branches
			invisible_branches
			commits_scroller_ref
			scroll_to_branch_tip
			scroll_pixel_buffer
			scroll_item_height
			selected_commit
			txt_filter
			txt_filter_ref
			hovered_branch_name
		}