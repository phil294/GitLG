import colors from "./colors.coffee"
import { is_truthy } from "./types"

``###*
# @typedef {import('./types').GitRef} GitRef
# @typedef {import('./types').Branch} Branch
# @typedef {import('./types').Vis} Vis
# @typedef {import('./types').Commit} Commit
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

``###*
# @returns all known branches *from that data* (branches outside are invisible) and the very
# data transformed into commits. A commit is git commit info and its vis
# (git graph visual representation branch lines). This vis-branch association
# extraction is the main purpose of this function.
# @param log_data {string}
# @param branch_data {string}
# @param separator {string}
###
parse = (log_data, branch_data, separator) =>
	lines = log_data.split '\n'

	``###* @type {Branch[]} ###
	branches = []
	``###* @returns {Branch} ###
	new_branch = (###* @type string ### branch_name, ###* @type string ### remote_name) =>
		branches.push
			name: branch_name
			color: undefined
			type: "branch"
			remote_name: remote_name
			id: if remote_name then "#{remote_name}/#{branch_name}" else branch_name
		branches[branches.length - 1]
	new_virtual_branch = =>
		branch = new_branch ''
		branch.virtual = true
		branch

	for branch_line from branch_data.split('\n')
		# refs/heads/local-branch-name
		# refs/remotes/origin-name/remote-branch-name
		if branch_line.startsWith("refs/heads/")
			new_branch(branch_line.slice(11))
		else
			[remote_name, ...remote_branch_name_parts] = branch_line.slice(13).split('/')
			new_branch(remote_branch_name_parts.join('/'), remote_name)
	# Not actually a branch but since it's included in the log refs and is neither stash nor tag
	# and checking it out works, we can just treat it as one:
	new_branch 'HEAD'

	``###* @type {Commit[]} ###
	commits = []
	
	vis_max_length = 0
	graph_chars = ['*', '\\', '/', ' ', '_', '|', ###rare:###'-', '.']
	for line, line_no in lines
		# Example line:
		# | | | * {SEP}fced73ef{SEP}phil294{SEP}e@mail.com{SEP}1557084465{SEP}HEAD -> master, origin/master, tag: xyz{SEP}Subject line
		# but can be anything due to different user input.
		# The vis part could be colored by supplying option `--color=always` in MainView.vue, but
		# this is not helpful as these colors are non-consistent and not bound to any branches
		[ vis_str = '', hash = '', author_name = '', author_email = '', timestamp = '', refs_csv = '', subject = '' ] = line.split separator
		if vis_str.at(-1) != ' '
			console.warn "unknown git graph syntax returned at line " + line_no
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
						console.error "Could not find ref '#{id}' in list of branches for commit '#{hash}'"
						undefined
			.filter is_truthy
			.sort git_ref_sort
		branch_tips = refs
			.filter (r) => r.type == "branch"
		branch_tip = branch_tips[0]

		``###* @type {typeof graph_chars} ###
		vis = vis_str.trimEnd().split('')
		vis_max_length = Math.max(vis_max_length, vis.length)
		if vis.some (v) => not graph_chars.includes(v)
			throw new Error "unknown visuals syntax at line " + line_no
		datetime =
			if timestamp
				new Date(Number(timestamp) * 1000).toISOString().slice(0,19).replace("T"," ")
			else undefined
		commits[line_no] = {
			i: line_no
			vis: []
			hash, author_name, author_email, datetime, refs, subject
			scroll_height: if hash then 20 else 6 # must be synced with css (v-bind doesn't work with coffee)
		}
		for char, i in vis by -1
			``###* @type {Branch | null | undefined } ###
			branch = undefined
			v_n = commits[line_no-1]?.vis[i]
			v_nw = commits[line_no-1]?.vis[i-1]
			v_w_char = vis[i-1] # not yet in commits[] as iteration is rtl
			v_ne = commits[line_no-1]?.vis[i+1]
			v_nee = commits[line_no-1]?.vis[i+2]
			v_e = commits[line_no]?.vis[i+1]
			v_ee = commits[line_no]?.vis[i+2]
			switch char
				when '*'
					if branch_tip
						branch = branch_tip
						if ['\\','⎺\\⎽','⎺\\'].includes(v_nw?.char||'')
							# This is branch tip but in previous above lines, this branch
							# was already on display for merging without its actual name known (virtual substitute).
							# Fix these lines (min 1) now
							wrong_branch = v_nw?.branch
							if not wrong_branch then throw new Error "wrong branch missing at line " + line_no
							k = line_no - 1
							while (matches = commits[k]?.vis.filter (v) => v.branch == wrong_branch)?.length
								for match from matches or []
									match.branch = branch
								k--
							branches.splice branches.indexOf(wrong_branch), 1
							char = '⎺*'
					else if v_n?.branch
						branch = v_n?.branch
					else if ['\\','⎺\\⎽','⎺\\'].includes(v_nw?.char||'')
						branch = v_nw?.branch
						char = '⎺*'
					else if ['/','/⎺'].includes(v_ne?.char||'')
						branch = v_ne?.branch
						char = '*⎺'
					else
						branch = new_virtual_branch()
					commits[line_no].branch = branch if branch
				when '|'
					if v_n?.branch
						branch = v_n?.branch
					else if ['\\','⎺\\⎽','⎺\\'].includes(v_nw?.char||'')
						branch = v_nw?.branch
						char = '⎺|'
					else if ['/','/⎺'].includes(v_ne?.char||'')
						branch = v_ne?.branch
						char = '|⎺'
					else
						throw new Error 'no neighbor found for | at line ' + line_no
				when '_'
					branch = v_ee?.branch
				when '/'
					if ['*','⎺*','*⎺'].includes(v_ne?.char||'')
						branch = v_ne?.branch
						char = '/⎺'
					else if ['|','⎺|','|⎺'].includes(v_ne?.char||'')
						if ['/','/⎺'].includes(v_nee?.char||'') or v_nee?.char == '_'
							branch = v_nee?.branch
						else
							branch = v_ne?.branch
							char = '/⎺'
					else if ['/','/⎺'].includes(v_ne?.char||'')
						branch = v_ne?.branch
					else if['\\','⎺\\⎽','⎺\\'].includes( v_n?.char||'') or ['|','⎺|','|⎺'].includes(v_n?.char||'')
						branch = v_n?.branch
						# TODO:
						# if ['|','⎺|','|⎺'].includes(v_n?.char||'')
						#	char = ?
					else
						throw new Error 'no neighbor found for / at line ' + line_no
				when '\\'
					if ['|','⎺|','|⎺'].includes(v_e?.char||'')
						branch = v_e?.branch
						char = '⎺\\⎽'
					else if ['|','⎺|','|⎺'].includes(v_w_char)
						# right before (chronologically) a merge commit (which would be at v_nw).
						# we can't know the actual branch yet (if it even still exists at all), the last branch
						# commit is somewhere further down.
						branch = new_virtual_branch()
						char = '⎺\\'
					else if ['|','⎺|','|⎺'].includes(v_nw?.char||'') or ['\\','⎺\\⎽','⎺\\'].includes(v_nw?.char||'')
						branch = v_nw?.branch
						if ['|','⎺|','|⎺'].includes(v_nw?.char||'')
							char = '⎺\\'
					else if v_nw?.char == '.' or v_nw?.char == '-'
						k = i - 2
						while (match = commits[line_no-1].vis[k])?.char == '-'
							k--
						branch = match.branch
					else if v_nw?.char == '.' and commits[line_no-1]?.vis[i-2].char == '-'
						branch = commits[line_no-1]?.vis[i-3].branch
					else
						throw new Error 'no neighbor found for \\ at line ' + line_no
				when ' ', '.', '-'
					branch = null
					# TODO:
					# set char to ⎺-like?
			if branch == undefined
				throw new Error 'unexpected undefined branch at line ' + line_no
			commits[line_no].vis[i] = {
				char
				branch
			}

	# cannot do this at creation because branches list is not fixed before this (see wrong_branch)
	i = -1
	for branch from branches
		branch.color = switch branch.name
			when 'master', 'main' then '#ff3333'
			when 'development', 'develop', 'dev' then '#009000'
			when 'stage', 'staging' then '#d7d700'
			else
				i++
				colors[i % (colors.length - 1)]
	
	branches = branches
		.filter (branch) =>
			# these exist in vis (with colors), but don't mention them in the listing
			not branch.virtual
		.sort git_ref_sort
		.slice(0, 350)

	{ commits, branches, vis_max_length }

export { parse }