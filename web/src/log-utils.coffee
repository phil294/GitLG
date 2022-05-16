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
	#
	###* @type {{ vis: {char: string, ref: string|null}[], hash: string, author_name: string, author_email: string, timestamp: number, refs_csv: string, subject: string }[]} ###
	commits = []
	#
	###* @type { Set<string> } ###
	all_refs = new Set
	graph_chars = ['*', '\\', '/', ' ', '_', '|']
	for line, line_no in lines
		# Example line:
		# | | | * {SEP}fced73ef{SEP}phil294{SEP}e@mail.com{SEP}1557084465{SEP}refs/tags/xyz{SEP}HEAD -> master, origin/master, tag: xyz{SEP}Subject line
		# but can be anything due to different user input
		[ vis_str = '', hash = '', author_name = '', author_email = '', timestamp = '', source_ref = '', refs_csv = '', subject = '' ] = line.split separator
		if vis_str.at(-1) != ' '
			throw line
		#
		###* @type {typeof graph_chars} ### # TODO with graph_chars as const, and without typeof no error?? should be error when case '*' becomes case '*MMM'
		vis = vis_str.trim().split('')
		if vis.some (v) => not graph_chars.includes(v)
			throw line
		commits[line_no] = { vis: [], hash, author_name, author_email, timestamp: Number(timestamp)*1000, refs_csv, subject }
		for char, i in vis by -1
			switch char
				when '*'
					###* @type {string|null} ###
					ref = source_ref
					char = '*'
				when '|'
					prev_above_1 = commits[line_no-1].vis[i]
					if prev_above_1?.char
						ref = prev_above_1.ref
					else
						prev_left_1 = commits[line_no-1].vis[i-1]
						if prev_left_1?.char
							ref = prev_left_1.ref
						else
							prev_right_1 = commits[line_no-1].vis[i+1]
							if not prev_right_1?.char
								throw 'missing | prev char ' + line_no + ' ' + line
							ref = prev_right_1.ref
				when '_'
					ref = commits[line_no].vis[i+2].ref
				when '/'
					prev_right_2 = commits[line_no-1]?.vis[i+1]
					if prev_right_2
						switch prev_right_2.char
							when '*'
								ref = prev_right_2.ref
							when '|'
								sec_prev_right_2 = commits[line_no-1].vis[i+2]
								if sec_prev_right_2?.char == '/'
									ref = sec_prev_right_2.ref
								else
									ref = prev_right_2.ref
							else
								throw 'unexpected prev right char ' + line_no + ' ' + line
					else
						prev_above_2 = commits[line_no-1]?.vis[i]
						if not prev_above_2
							throw 'missing prev char ' + line_no + ' ' + line
						switch prev_above_2.char
							when '\\'
								ref = prev_above_2.ref # which is always null because \ isn't queried downwards. but should stay for inverse logic tbd
							else
								throw 'unexpected prev left char ' + line_no + ' ' + line
				when '\\'
					ref = null
				when ' '
					ref = null
				else
					throw 'unexpected char ' + char + ' ' + line_no + ' ' + line
			commits[line_no].vis[i] = { char, ref }
			if ref
				all_refs.add ref
	{ commits, refs: [...all_refs] }

export { parse }