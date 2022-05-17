###*
# @returns all known refs *from that data* (refs outside are invisible) and the very
# data transformed into commits. A commit is git commit info and its vis
# (git graph visual representation branch lines). This vis-ref association
# extraction is the main purpose of this function.
# @param data {string}
# @param separator {string}
###
parse = (data, separator) =>
	lines = data.split '\n'
	_virtual_branch_i = 0
	#
	###* @type {{ vis: {char: string, ref: string|null}[], hash: string, author_name: string, author_email: string, timestamp: number, refs: string[], subject: string }[]} ###
	commits = []
	#
	###* @type { Set<string> } ###
	all_refs = new Set
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
		branch = branch_tips[0]
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
				when '*'
					if branch
						###* @type {string} ###
						ref = branch
						if v_nw?.char == '\\'
							# This is branch tip but in previous above lines, this branch
							# was already on display for merging without its actual name known.
							# Fix these lines (min 1) now
							k = line_no - 1
							while (matches = commits[k]?.vis.filter (v) => v.ref == v_nw?.ref)?.length
								for match from matches or []
									match.ref = branch
								k--
							_virtual_branch_i--
					else if v_n?.ref
						ref = v_n?.ref
					else if v_nw?.char == '\\'
						ref = v_nw?.ref
					else if v_ne?.char == '/'
						ref = v_ne?.ref
					else
						ref = new_virtual_branch()
				when '|'
					# todo duplicate code
					if v_n?.ref
						ref = v_n?.ref
					else if v_nw?.char == '\\'
						ref = v_nw?.ref
					else if v_ne?.char == '/'
						ref = v_ne?.ref
					else
						throw new Error 'no neighbor found for | at line ' + line_no
				when '_'
					ref = v_ee?.ref
				when '/'
					if v_ne?.char == '*'
						ref = v_ne?.ref
					else if v_ne?.char == '|'
						if v_nee?.char == '/' or v_nee?.char == '_'
							ref = v_nee?.ref
						else
							ref = v_ne?.ref
					else if v_ne?.char == '/'
						ref = v_ne?.ref
					else if v_n?.char == '\\' or v_n?.char == '|'
						ref = v_n?.ref
					else
						throw new Error 'no neighbor found for / at line ' + line_no
				when '\\'
					if v_e?.char == '|'
						ref = v_e?.ref
					else if v_w_char == '|'
						# right before (chronologically) a merge commit (which would be at v_nw)
						if v_nw?.char != '*'
							# TODO keep? 
							throw new Error "expected merge * before |\\ at line " + line_no
						# we can't know the actual branch yet (if it even still exists at all), the last branch
						# commit is somewhere further down.
						ref = new_virtual_branch()
					else if v_nw?.char == '|' or v_nw?.char == '\\'
						ref = v_nw?.ref
					else if v_nw?.char == '.' or v_nw?.char == '-'
						k = i - 2
						while (match = commits[line_no-1].vis[k])?.char == '-'
							k--
						ref = match.ref
					else if v_nw?.char == '.' and commits[line_no-1]?.vis[i-2].char == '-'
						ref = commits[line_no-1]?.vis[i-3].ref
					else
						throw new Error 'no neighbor found for \\ at line ' + line_no
				when ' ', '.', '-'
					ref = null
			if ref == undefined
				throw new Error 'unexpected undefined ref at line ' + line_no
			if ref != null
				all_refs.add ref
			commits[line_no].vis[i] = { char, ref }
	{ commits, refs: [...all_refs], vis_max_length }

export { parse }