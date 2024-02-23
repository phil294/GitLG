import colors from "./colors.coffee"
import { is_truthy, is_branch } from "./types"

###*
# @typedef {import('./types').GitRef} GitRef
# @typedef {import('./types').Branch} Branch
# @typedef {import('./types').VisLine} VisLine
# @typedef {import('./types').Commit} Commit
###

###*
# @typedef {{
#	char: string
#	branch: Branch | null
# }[]} Vis
# Chars as they are returned from git, with proper branch association
###

git_ref_sort = (###* @type {GitRef} ### a, ###* @type {GitRef} ### b) =>
	a_is_tag = a.id.startsWith("tag: ")
	b_is_tag = b.id.startsWith("tag: ")
	# prefer branch over tag/stash
	Number(a_is_tag or not a.id.startsWith("refs/")) - Number(b_is_tag or not b.id.startsWith("refs/")) or
		# prefer tag over stash
		Number(b_is_tag) - Number(a_is_tag) or
		# prefer local branch over remote branch
		a.id.indexOf("/") - b.id.indexOf("/")

###*
# @returns all branches and the very
# data transformed into commits. A commit is git commit info and its vis lines
# (git graph visual representation branch lines). This vis-branch association
# extraction is the main purpose of this function.
# @param log_data {string}
# @param branch_data {string}
# @param stash_data {string}
# @param separator {string}
# @param curve_radius {number}
###
parse = (log_data, branch_data, stash_data, separator, curve_radius) =>
	rows = log_data.split '\n'

	###* @type {Branch[]} ###
	branches = []
	new_branch = (###* @type string ### branch_name, ###* @type string= ### remote_name, ###* @type string= ### tracking_remote_name) =>
		###* @type Branch ###
		branch =
			name: branch_name
			color: undefined
			type: "branch"
			remote_name: remote_name
			tracking_remote_name: tracking_remote_name
			id: if remote_name then "#{remote_name}/#{branch_name}" else branch_name
		branches.push branch
		branch

	for branch_line from branch_data.split('\n')
		# origin-name{SEP}refs/heads/local-branch-name
		# {SEP}refs/remotes/origin-name/remote-branch-name
		[tracking_remote_branch_name, ref_name] = branch_line.split(separator)
		if ref_name.startsWith("refs/heads/")
			new_branch(ref_name.slice(11), undefined, tracking_remote_branch_name)
		else
			[remote_name, ...remote_branch_name_parts] = ref_name.slice(13).split('/')
			new_branch(remote_branch_name_parts.join('/'), remote_name)
	# Not actually a branch but since it's included in the log refs and is neither stash nor tag
	# and checking it out works, we can just treat it as one:
	new_branch 'HEAD'

	###* @type {Commit[]} ###
	commits = []

	###* @type Vis ###
	last_vis = []

	###* vis svg lines are accumulated possibly spanning multiple output rows until
	# there is a commit ("*") in which case the lines are saved as collected.
	# This means that we only show commit rows and the various connection lines are
	# densened together.
	# @type {Record<string, VisLine>} ###
	densened_vis_line_by_branch_id = {}
	###* @type {Record<string, VisLine>} ###
	last_densened_vis_line_by_branch_id = {}
	###* @type {Record<string, number>} ###
	xn_by_branch_id = {}

	graph_chars = ['*', '\\', '/', ' ', '_', '|', ###rare:###'-', '.']
	hash = '' # Fixing type error idk
	for row, row_no in rows
		# Example row:
		# | | | * {SEP}fced73efd3eb8012953ddc0e533c7a4ec64f0b46#{SEP}fced73ef{SEP}phil294{SEP}e@mail.com{SEP}1557084465{SEP}HEAD -> master, origin/master, tag: xyz{SEP}Subject row
		# but can be anything due to different user input.
		# The vis part could be colored by supplying option `--color=always` in MainView.vue, but
		# this is not helpful as these colors are non-consistent and not bound to any branches
		[ vis_str = '', hash_long =  '', hash = '', author_name = '', author_email = '', iso_datetime = '', refs_csv = '', subject = '' ] = row.split separator
		# Much, much slower than everything else so better not log
		# if vis_str.at(-1) != ' '
		# 	console.warn "unknown git graph syntax returned at row " + row_no
		refs = refs_csv
			.split ', '
			# map to ["master", "origin/master", "tag: xyz"]
			.map (r) => r.split(' -> ')[1] or r
			.filter (r) => r != 'refs/stash'
			.filter is_truthy
			.map (id) =>
				if id.startsWith("tag: ")
					###* @type {GitRef} ###
					ref =
						id: id
						name: id.slice(5)
						color: undefined
						type: "tag"
					ref
				else
					branch_match = branches.find (branch) => id == branch.id
					if branch_match
						branch_match
					else
						# Can happen with grafted branches
						console.warn "Could not find ref '#{id}' in list of branches for commit '#{hash}'"
						undefined
			.filter is_truthy
			.sort git_ref_sort
		branch_tips = refs
			.filter is_branch
		branch_tip = branch_tips[0]

		###* @type {typeof graph_chars} ###
		vis_chars = vis_str.trimEnd().split('')
		if vis_chars.some (v) => not graph_chars.includes(v)
			throw new Error "Could not parse output of GIT LOG (line:#{row_no}). Did you change the command by hand? Please in the main view at the top left, click \"Configure\", then at the top right click \"Reset\", then \"Save\" and try again. If this didn't help, it might be a bug! Please open up a GitHub issue."
		# format %ad with --date=iso-local returns something like 2021-03-02 15:59:43 +0100
		datetime = iso_datetime?.slice(0, 19)
		###* We only keep track of the chars used by git output to be able to reconstruct
		# branch lines accordingly, as git has no internal concept of this.
		# This is achieved by comparing the vis chars to its neighbors (`last_vis`).
		# Once this process is complete, the vis chars are dismissed and we only keep the
		# vis lines per commit spanning 1-n rows to be rendered eventually.
		# @type Vis ###
		vis = []
		###* @type {Branch|undefined} ###
		commit_branch = undefined
		for char, i in vis_chars by -1
			###* @type {Branch | null | undefined } ###
			v_branch = undefined
			v_n = last_vis[i]
			v_nw = last_vis[i-1]
			v_w_char = vis_chars[i-1] # not yet in vis[] as iteration is rtl
			v_ne = last_vis[i+1]
			v_nee = last_vis[i+2]
			v_e = vis[i+1]
			v_ee = vis[i+2]
			###* Parsing from top to bottom (reverse chronologically). The flow is
			# generally rtl horizontally. So for example, the "/" char would direct the
			# branch line from top right to bottom left and thus yield a {x0:1,xn:0} vis line.
			# @type VisLine ###
			vis_line = {}
			switch char
				when '*'
					if branch_tip
						v_branch = branch_tip
						if v_nw?.char == '\\'
							# This is branch tip but in previous above lines, this branch
							# may already have been on display for merging without its actual name known (inferred substitute).
							# Fix these lines (min 1) now
							wrong_branch = v_nw?.branch
							if wrong_branch
								k = commits.length - 1
								while (wrong_branch_matches = commits[k]?.vis_lines.filter (v) => v.branch == wrong_branch)?.length
									for wrong_branch_match from wrong_branch_matches or []
										wrong_branch_match.branch = v_branch
									k--
								branches.splice branches.indexOf(wrong_branch), 1
					else if v_n?.branch
						v_branch = v_n?.branch
					else if v_nw?.char == '\\'
						v_branch = v_nw?.branch
					else if v_ne?.char == '/'
						v_branch = v_ne?.branch
					else
						# Stashes
						v_branch = new_branch "inferred~#{branches.length-1}"
						v_branch.inferred = true
					commit_branch = v_branch || undefined
					vis_line = { x0: 0.5, xn: 0.5 }
					if ! last_vis[i] || ! last_vis[i].char || last_vis[i].char == ' '
						# Branch or inferred branch starts here visually (ends here logically)
						vis_line.y0 = 0.5
				when '|'
					if v_n?.branch
						v_branch = v_n?.branch
					else if v_nw?.char == '\\'
						v_branch = v_nw?.branch
					else if v_ne?.char == '/'
						v_branch = v_ne?.branch
					else
						throw new Error 'no neighbor found for | at row ' + row_no
					vis_line = { x0: 0.5, xn: 0.5, yn: 0.5 }
				when '_'
					v_branch = v_ee?.branch
					vis_line = { x0: 1, xn: 0 }
				when '/'
					if v_ne?.char == '*'
						v_branch = v_ne?.branch
					else if v_ne?.char == '|'
						if v_nee?.char == '/' or v_nee?.char == '_'
							v_branch = v_nee?.branch
						else
							v_branch = v_ne?.branch
					else if v_ne?.char == '/'
						v_branch = v_ne?.branch
					else if v_n?.char == '\\' or v_n?.char == '|'
						v_branch = v_n?.branch
					else
						throw new Error 'no neighbor found for / at row ' + row_no
					vis_line = { x0: 1, xn: -0.5, xce: 0.5 }
				when '\\'
					if v_e?.char == '|'
						v_branch = v_e?.branch
					else if v_w_char == '|'
						# right before (chronologically) a merge commit (which would be at v_nw).
						last_commit = commits.at(-1)
						last_commit?.merge = true
						# The actual branch name isn't known for sure yet: It will either a.) be visible with a branch tip
						# in the next commit or never directly exposed, in which case we'll b.) try to infer it from the
						# merge commit message, or if failing to do so, c.) create a inferred branch without name.
						# b.) and c.) will be overwritten again if a.) occurs [see "inferred substitute"].
						if subject_merge_match = last_commit?.subject.match /^Merge (?:(?:remote[ -]tracking )?branch '([^ ]+)'.*)|(?:pull request #[0-9]+ from (.+))$/
							branch_id = (subject_merge_match[1] || subject_merge_match[2]) + '~' + (branches.length - 1)
							split = branch_id.split '/'
							if split.length
								v_branch = new_branch split.at(-1)||'', split.slice(0, split.length - 1).join('/')
							else
								v_branch = new_branch branch_id
						else
							v_branch = new_branch "~#{branches.length-1}"
						v_branch.inferred = true
					else if v_nw?.char == '|' or v_nw?.char == '\\'
						v_branch = v_nw?.branch
					else if v_nw?.char == '.' or v_nw?.char == '-'
						k = i - 2
						while (w_char_match = last_vis[k])?.char == '-'
							k--
						v_branch = w_char_match.branch
					else if v_nw?.char == '.' and last_vis[i-2].char == '-'
						v_branch = last_vis[i-3].branch
					else
						throw new Error 'no neighbor found for \\ at row ' + row_no
					vis_line = { x0: -0.5, xn: 1 }
				when ' ', '.', '-'
					v_branch = null
			if v_branch == undefined
				throw new Error "could not identify branch in row #{row_no} at char #{i}"
			vis[i] = {
				char
				branch: v_branch
			}
			if v_branch
				vis_line.x0 += i
				vis_line.xn += i
				if vis_line.xcs?
					vis_line.xcs += i
				if vis_line.xce?
					vis_line.xce += i
				if densened_vis_line_by_branch_id[v_branch.id]
					densened_vis_line_by_branch_id[v_branch.id].xn = vis_line.xn
					densened_vis_line_by_branch_id[v_branch.id].xce = vis_line.xce
				else
					vis_line.branch = v_branch
					densened_vis_line_by_branch_id[v_branch.id] = vis_line
				xn_by_branch_id[v_branch.id] = vis_line.xn
		if subject
			# After 1-n parsed rows, we have now arrived at what will become one row
			# in *our* application too.
			for branch_id, vis_line of densened_vis_line_by_branch_id
				# Usually constant
				if ! vis_line.y0?
					vis_line.y0 = 0
				if ! vis_line.yn?
					vis_line.yn = 1
				if ! vis_line.xce?
					# We don't know yet if this line is the last one of rows for this branch
					# or if more will be to come. The latter case is handled later, so for the former
					# case to look nice, some downwards angle is added by default by moving the end
					# control point upwards. This makes sense because the last line is the birth
					# spot and branches are always based on another branch, so this draws an
					# upwards splitting effect
					vis_line.xce = vis_line.xn
				if ! vis_line.yce?
					vis_line.yce = 1 - (curve_radius / 2) # Must not be too strong
				# Make connection to previous row's branch line curvy?
				if last_vis_line = last_densened_vis_line_by_branch_id?[branch_id]
					# So far, a line is simply defined as the connection between x0 and xn with
					# y0 and y1 being 0 and 1, respectively. The lines all connect to each
					# other. But between them, there is no curvature yet (hard edge).
					# Determining two control points near this junction:
					# (see VisLine JSDoc for naming info)
					last_xce = last_vis_line.x0 + (last_vis_line.xn - last_vis_line.x0) * (1 - curve_radius)
					xcs = vis_line.x0 + (vis_line.xn - vis_line.x0) * curve_radius
					# ...and the strategy for creating a curve is to mark the control points fixed
					# but move the actual junction point's x toward the average between both control
					# points:
					middle_x = (xcs + last_xce) / 2
					last_vis_line.xn = middle_x
					last_vis_line.xce = last_xce
					last_vis_line.yce = 1 - curve_radius
					last_vis_line.yn = 1
					vis_line.x0 = middle_x
					vis_line.xcs = xcs
					vis_line.ycs = curve_radius
				else
					if ! vis_line.xcs?
						# First time this branch appeared
						if vis_line.xn > vis_line.x0
							# so we want an upwards curvature, just like
							# the logic around initializing xce at '/' above, but reversed:
							vis_line.xcs = vis_line.x0 + 1
						else
							vis_line.xcs = vis_line.x0
					vis_line.ycs = curve_radius
			commits.push {
				i: row_no
				vis_lines: Object.values(densened_vis_line_by_branch_id)
					# Leftmost branches should appear later so they are on top of the rest
					.sort (a, b) => (b.xcs || 0) + (b.xce || 0) - (a.xcs || 0) - (a.xce || 0)
				branch: commit_branch
				hash_long, hash, author_name, author_email, datetime, refs, subject
			}
			last_densened_vis_line_by_branch_id = densened_vis_line_by_branch_id
			# Get rid of branches that "end" here (those that were born with this very commit)
			# as won't paint their lines anymore in future (= older) commits, *and*
			# get rid of collected connection lines - freshly start at this commit again
			densened_vis_line_by_branch_id = {}
		last_vis = vis

	# cannot do this at creation because branches list is not fixed before this (see "inferred substitute")
	for branch in branches
		branch.color = switch branch.name
			when 'master', 'main' then '#ff3333'
			when 'development', 'develop', 'dev' then '#009000'
			when 'stage', 'staging', 'production' then '#d7d700'
			else
				colors[Math.abs(branch.name.hashCode() % colors.length)]

	branches = branches
		.filter (branch) =>
			# these exist in vis (with colors), but don't mention them in the listing
			not branch.inferred
		.sort git_ref_sort
		.slice(0, 10000)

	# stashes were queried (git reflog show stash) but shown as commits. Need to add refs:
	for stash from (stash_data or '').split('\n')
		# 7c37db63 stash@{11}
		split = stash.split(' ')
		commit = commits.find((c) => c.hash == split[0])
		name = split.slice(1).join(' ')
		commit?.refs.push
			name: name
			id: name
			type: "stash"
			color: '#fff'

	{ commits, branches }

export { parse }