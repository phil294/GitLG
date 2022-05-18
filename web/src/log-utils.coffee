###*
# @returns all known branches *from that data* (branches outside are invisible) and the very
# data transformed into commits. A commit is git commit info and its vis
# (git graph visual representation branch lines). This vis-branch association
# extraction is the main purpose of this function.
# @param data {string}
# @param separator {string}
###
parse = (data, separator) =>
	lines = data.split '\n'
	_virtual_branch_i = 0
	#
	###* @type {{ vis: {char: string, branch: string|null}[], hash: string, author_name: string, author_email: string, timestamp: number, refs: string[], subject: string }[]} ###
	commits = []
	#
	###* @type { Set<string> } ###
	all_branches = new Set
	vis_max_length = 0
	graph_chars = ['*', '\\', '/', ' ', '_', '|', ###rare: ###'-', '.']
	for line, line_no in lines
		# Example line:
		# | | | * {SEP}fced73ef{SEP}phil294{SEP}e@mail.com{SEP}1557084465{SEP}HEAD -> master, origin/master, tag: xyz{SEP}Subject line
		# but can be anything due to different user input.
		# The vis part could be colored by supplying option `--color=always` in MainView.vue, but
		# this is not helpful as these colors are non-consistent and not bound to any branches
		[ vis_str = '', hash = '', author_name = '', author_email = '', timestamp = '', refs_csv = '', subject = '' ] = line.split separator
		if vis_str.at(-1) != ' '
			throw new Error "unknown syntax at line " + line_no
		# ["master", "origin/master", "tag: xyz"]
		refs = refs_csv
			.split ', '
			.map (r) => r.split(' -> ')[1] or r
			.filter Boolean
			.sort (a, b) =>
				a_is_tag = a.startsWith("tag: ")
				b_is_tag = b.startsWith("tag: ")
				# prefer branch over tag/stash
				Number(a_is_tag or not a.startsWith("refs/")) - Number(b_is_tag or not b.startsWith("refs/")) or
					# prefer tag over stash
					Number(b_is_tag) - Number(a_is_tag) or
					# prefer local branch over remote branch
					a.indexOf("/") - b.indexOf("/")
		branch_tips = refs
			.filter (r) => not r.startsWith("tag: ") and not r.startsWith("refs/")
		branch_tip = branch_tips[0]
		new_virtual_branch = =>
			'virtual_branch_' + (++_virtual_branch_i)
		#
		###* @type {typeof graph_chars} ### # TODO with graph_chars as const, and without typeof no error?? should be error when case '*' becomes case '*MMM'
		vis = vis_str.trimEnd().split('')
		vis_max_length = Math.max(vis_max_length, vis.length)
		if vis.some (v) => not graph_chars.includes(v)
			throw new Error "unknown visuals syntax at line " + line_no
		commits[line_no] = { vis: [], hash, author_name, author_email, timestamp: Number(timestamp)*1000, refs, subject }
		for char, i in vis by -1
			v_n = commits[line_no-1]?.vis[i]
			v_nw = commits[line_no-1]?.vis[i-1]
			v_w_char = vis[i-1] # not yet in commits[] as iteration is rtl
			v_ne = commits[line_no-1]?.vis[i+1]
			v_nee = commits[line_no-1]?.vis[i+2]
			v_e = commits[line_no]?.vis[i+1]
			v_ee = commits[line_no]?.vis[i+2]
			switch char
				# todo refactor / check these for duplicate code
				when '*'
					if branch_tip
						###* @type {string} ###
						branch = branch_tip
						if v_nw?.char == '\\'
							# This is branch tip but in previous above lines, this branch
							# was already on display for merging without its actual name known (virtual substitute).
							# Fix these lines (min 1) now
							wrong_branch = v_nw?.branch or ''
							k = line_no - 1
							while (matches = commits[k]?.vis.filter (v) => v.branch == wrong_branch)?.length
								for match from matches or []
									match.branch = branch
								k--
							_virtual_branch_i--
							all_branches.delete wrong_branch
					else if v_n?.branch
						branch = v_n?.branch
					else if v_nw?.char == '\\'
						branch = v_nw?.branch
					else if v_ne?.char == '/'
						branch = v_ne?.branch
					else
						branch = new_virtual_branch()
				when '|'
					if v_n?.branch
						branch = v_n?.branch
					else if v_nw?.char == '\\'
						branch = v_nw?.branch
					else if v_ne?.char == '/'
						branch = v_ne?.branch
					else
						throw new Error 'no neighbor found for | at line ' + line_no
				when '_'
					branch = v_ee?.branch
				when '/'
					if v_ne?.char == '*'
						branch = v_ne?.branch
					else if v_ne?.char == '|'
						if v_nee?.char == '/' or v_nee?.char == '_'
							branch = v_nee?.branch
						else
							branch = v_ne?.branch
					else if v_ne?.char == '/'
						branch = v_ne?.branch
					else if v_n?.char == '\\' or v_n?.char == '|'
						branch = v_n?.branch
					else
						throw new Error 'no neighbor found for / at line ' + line_no
				when '\\'
					if v_e?.char == '|'
						branch = v_e?.branch
					else if v_w_char == '|'
						# right before (chronologically) a merge commit (which would be at v_nw)
						if v_nw?.char != '*'
							# TODO keep? 
							throw new Error "expected merge * before |\\ at line " + line_no
						# we can't know the actual branch yet (if it even still exists at all), the last branch
						# commit is somewhere further down.
						branch = new_virtual_branch()
					else if v_nw?.char == '|' or v_nw?.char == '\\'
						branch = v_nw?.branch
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
			if branch == undefined
				throw new Error 'unexpected undefined branch at line ' + line_no
			if branch != null
				all_branches.add branch
			commits[line_no].vis[i] = { char, branch }
	branches = [...all_branches]
	{ commits, branches, vis_max_length }

export { parse }