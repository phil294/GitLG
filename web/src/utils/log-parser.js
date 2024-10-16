import colors from './colors.js'

/**
 * @typedef {{
 *	char: string
 *	branch: Branch | null
 * }[]} Vis
 * Chars as they are returned from git, with proper branch association
 */

function git_ref_sort(/** @type {GitRef} */ a, /** @type {GitRef} */ b) {
	let a_is_tag = a.id.startsWith('tag: ')
	let b_is_tag = b.id.startsWith('tag: ')
	// prefer branch over tag/stash
	// prefer tag over stash
	// prefer local branch over remote branch
	return Number(a_is_tag || ! a.id.startsWith('refs/')) - Number(b_is_tag || ! b.id.startsWith('refs/')) || Number(b_is_tag) - Number(a_is_tag) || a.id.indexOf('/') - b.id.indexOf('/')
}

/**
 * @returns all branches and the very
 * data transformed into commits. A commit is git commit info and its vis lines
 * (git graph visual representation branch lines). This vis-branch association
 * extraction is the main purpose of this function.
 * @param log_data {string}
 * @param branch_data {string}
 * @param stash_data {string}
 * @param separator {string}
 * @param curve_radius {number}
 */
function parse(log_data, branch_data, stash_data, separator, curve_radius) {
	let rows = log_data.split('\n')

	/** @type {Branch[]} */
	let branches = []
	/**
	 * @param name {string}
	 * @param options {{ remote_name?: string, tracking_remote_name?: string, inferred?: boolean, name_may_include_remote?: boolean}}=
	 */
	function new_branch(name, { remote_name, tracking_remote_name, inferred, name_may_include_remote } = {}) {
		if (name_may_include_remote && ! remote_name && name.includes('/')) {
			let split = name.split('/')
			name = split.at(-1) || ''
			remote_name = split.slice(0, split.length - 1).join('/')
		}
		if (! name && inferred)
			name = `${branches.length - 1}`
		/** @type {Branch} */
		let branch = {
			name,
			color: undefined,
			type: 'branch',
			remote_name,
			tracking_remote_name,
			id: (remote_name ? `${remote_name}/${name}` : name) + (inferred ? '~' + (branches.length - 1) : ''),
			inferred,
		}
		branches.push(branch)
		return branch
	}

	for (let branch_line of branch_data.split('\n')) {
		// origin-name{SEP}refs/heads/local-branch-name
		// {SEP}refs/remotes/origin-name/remote-branch-name
		let [tracking_remote_name, ref_name] = branch_line.split(separator)
		if (ref_name.startsWith('refs/heads/'))
			new_branch(ref_name.slice(11), { tracking_remote_name })
		else {
			let [remote_name, ...remote_branch_name_parts] = ref_name.slice(13).split('/')
			new_branch(remote_branch_name_parts.join('/'), { remote_name })
		}
	}
	// Not actually a branch but since it's included in the log refs and is neither stash nor tag
	// and checking it out works, we can just treat it as one:
	new_branch('HEAD')

	/** @type {Commit[]} */
	let commits = []

	/** @type {Vis} */
	let last_vis = []

	/**
	 * vis svg lines are accumulated possibly spanning multiple output rows until
	 * there is a commit ("*") in which case the lines are saved as collected.
	 * This means that we only show commit rows and the various connection lines are
	 * densened together.
	 * @type {Record<string, VisLine>}
	 */
	let densened_vis_line_by_branch_id = {}
	/** @type {Record<string, VisLine>} */
	let last_densened_vis_line_by_branch_id = {}

	let graph_chars = ['*', '\\', '/', ' ', '_', '|', /* rare: */ '-', '.']
	for (let [row_no_s, row] of Object.entries(rows)) {
		if (row === '... ')
			continue // with `--follow -- pathname`, this can happen even though we're specifying a strict --format.
		// Example row:
		// | | | * {SEP}fced73efd3eb8012953ddc0e533c7a4ec64f0b46#{SEP}fced73ef{SEP}phil294{SEP}e@mail.com{SEP}1557084465{SEP}HEAD -> master, origin/master, tag: xyz{SEP}Subject row
		// but can be anything due to different user input.
		// The vis part could be colored by supplying option `--color=always` in MainView.vue, but
		// this is not helpful as these colors are non-consistent and not bound to any branches
		let [vis_str = '', hash_long = '', hash = '', author_name = '', author_email = '', iso_datetime = '', refs_csv = '', subject = ''] = row.split(separator)
		// Much, much slower than everything else so better not log
		// if vis_str.at(-1) != ' '
		// 	console.warn "unknown git graph syntax returned at row " + row_no
		let refs = refs_csv
			.split(', ')
			// map to ["master", "origin/master", "tag: xyz"]
			.map((r) => r.split(' -> ')[1] || r)
			.filter((r) => r !== 'refs/stash')
			.filter(is_truthy)
			.map((id) => {
				if (id.startsWith('tag: ')) {
					/** @type {GitRef} */
					let ref = {
						id,
						name: id.slice(5),
						color: undefined,
						type: 'tag',
					}
					return ref
				} else {
					let branch_match = branches.find((branch) => id === branch.id)
					if (branch_match)
						return branch_match
					else {
						// Can happen with grafted branches
						console.warn(`Could not find ref '${id}' in list of branches for commit '${hash}'`)
						return undefined
					}
				}
			}).filter(is_truthy)
			.sort(git_ref_sort)
		let branch_tips = refs
			.filter(is_branch)
		let branch_tip = branch_tips[0]

		/** @type {typeof graph_chars} */
		let vis_chars = vis_str.trimEnd().split('')
		if (vis_chars.some((v) => ! graph_chars.includes(v)))
			throw new Error(`Could not parse output of GIT LOG (line:${row_no_s})`)
		// format %ad with --date=iso-local returns something like 2021-03-02 15:59:43 +0100
		let datetime = iso_datetime?.slice(0, 19)
		/**
		 * We only keep track of the chars used by git output to be able to reconstruct
		 * branch lines accordingly, as git has no internal concept of this.
		 * This is achieved by comparing the vis chars to its neighbors (`last_vis`).
		 * Once this process is complete, the vis chars are dismissed and we only keep the
		 * vis lines per commit spanning 1-n rows to be rendered eventually.
		 * @type {Vis}
		 */
		let vis = []
		/** @type {Branch|undefined} */
		let commit_branch = undefined
		for (let [i_s, char] of Object.entries(vis_chars).reverse()) {
			let i = Number(i_s)
			/** @type {Branch | null | undefined } */
			let v_branch = undefined
			let v_n = last_vis[i]
			let v_nw = last_vis[i - 1]
			let v_w_char = vis_chars[i - 1]
			let v_ne = last_vis[i + 1]
			let v_nee = last_vis[i + 2]
			let v_e = vis[i + 1]
			let v_ee = vis[i + 2]
			// Parsing from top to bottom (reverse chronologically), rtl horizontally
			// This line connects this commit with the previous one. There will be a second
			// line later for connecting to the follow-up one.
			/** @type {VisLine} */
			let vis_line = { x0: 0, xn: i + 0.5, y0: -0.5, yn: 0.5 }
			switch (char) {
				case '*':
					if (branch_tip)
						v_branch = branch_tip
					else if (v_n?.branch)
						v_branch = v_n?.branch
					else if (v_nw?.char === '\\')
						v_branch = v_nw?.branch
					else if (v_ne?.char === '/')
						v_branch = v_ne?.branch
					else
						// Stashes or no context because of --skip arg
						v_branch = new_branch('', { inferred: true })

					commit_branch = v_branch || undefined
					// if (! last_vis[i] || ! last_vis[i].char || last_vis[i].char === ' ')
					// 	Branch or inferred branch starts here visually (ends here logically)
					if (v_branch && v_nw?.char === '\\' && v_n?.char !== '|') {
						// This is branch tip but in previous above lines/commits, this branch
						// may already have been on display for merging without its actual name known ("inferred substitute" below).
						// Fix these lines (min 1) now
						let wrong_branch = v_nw?.branch
						if (wrong_branch?.inferred && ! v_branch.inferred) {
							let k = commits.length - 1
							let wrong_branch_matches = []
							while ((wrong_branch_matches = commits[k]?.vis_lines.filter((v) => v.branch === wrong_branch))?.length) {
								for (let wrong_branch_match of wrong_branch_matches || [])
									wrong_branch_match.branch = v_branch
								k--
							}
							if (densened_vis_line_by_branch_id[wrong_branch.id] && ! densened_vis_line_by_branch_id[v_branch.id]) {
								densened_vis_line_by_branch_id[v_branch.id] = densened_vis_line_by_branch_id[wrong_branch.id]
								densened_vis_line_by_branch_id[v_branch.id].branch = v_branch
								delete densened_vis_line_by_branch_id[wrong_branch.id]
							}
							branches.splice(branches.indexOf(wrong_branch), 1)
						}
					}
					break
				case '|':
					if (v_n?.branch)
						v_branch = v_n?.branch
					else if (v_nw?.char === '\\')
						v_branch = v_nw?.branch
					else if (v_ne?.char === '/')
						v_branch = v_ne?.branch
					break
				case '_':
					v_branch = v_ee?.branch
					break
				case '/':
					vis_line.xn -= 1
					if (v_ne?.char === '*')
						v_branch = v_ne?.branch
					else if (v_ne?.char === '|')
						if (v_nee?.char === '/' || v_nee?.char === '_')
							v_branch = v_nee?.branch
						else
							v_branch = v_ne?.branch
					else if (v_ne?.char === '/')
						v_branch = v_ne?.branch
					else if (v_n?.char === '\\' || v_n?.char === '|')
						v_branch = v_n?.branch
					break
				case '\\':
					vis_line.xn += 1
					if (v_w_char === '|' && v_nw.char === '*') {
						// right below a merge commit
						let last_commit = commits.at(-1)
						if (v_e?.char === '|' && v_e?.branch)
							// Actually the very same branch as v_e, but the densened_vis_line logic can only handle one line per branch at a time.
							v_branch = new_branch(v_e.branch.name, { ...v_e.branch })
						else {
							// The actual branch name isn't known for sure yet: It will either a.) be visible with a branch tip
							// in the next commit or never directly exposed, in which case we'll b.) try to infer it from the
							// merge commit message, or if failing to do so, c.) create an inferred branch without name.
							// b.) and c.) will be overwritten again if a.) occurs [see "inferred substitute"].
							let subject_merge_match = last_commit?.subject.match(/^Merge (?:(?:remote[ -]tracking )?branch '([^ ]+)'.*)|(?:pull request #[0-9]+ from (.+))$/)
							if (subject_merge_match)
								v_branch = new_branch(subject_merge_match[1] || subject_merge_match[2], { inferred: true, name_may_include_remote: true })
							else
								v_branch = new_branch('', { inferred: true })
						}
						if (last_commit)
							last_commit.merge = true
						let last_vis_line = last_densened_vis_line_by_branch_id[v_nw.branch?.id || -1]
						if (last_vis_line)
							// Can't rely on the normal last_vis_line logic as there is nothing to connect to
							vis_line.x0 = last_vis_line.xn
					} else if (v_nw?.char === '|' || v_nw?.char === '\\')
						v_branch = v_nw?.branch
					else if (v_nw?.char === '.' || v_nw?.char === '-') {
						let k = i - 2
						let w_char_match = null
						while ((w_char_match = last_vis[k])?.char === '-')
							k--
						v_branch = w_char_match.branch
					} else if (v_nw?.char === '.' && last_vis[i - 2].char === '-')
						v_branch = last_vis[i - 3].branch
					break
				case ' ': case '.': case '-':
					v_branch = null
			}
			vis[i] = {
				char,
				branch: v_branch || null,
			}

			if (v_branch)
				if (densened_vis_line_by_branch_id[v_branch.id])
					densened_vis_line_by_branch_id[v_branch.id].xn = vis_line.xn
				else {
					vis_line.branch = v_branch
					densened_vis_line_by_branch_id[v_branch.id] = vis_line
				}
		}
		if (subject) {
			// After 1-n parsed rows, we have now arrived at what will become one row
			// in *our* application too.
			for (let [branch_id, vis_line] of Object.entries(densened_vis_line_by_branch_id)) {
				vis_line.xce = vis_line.xn
				vis_line.yce = vis_line.yn
				vis_line.xcs = vis_line.x0
				vis_line.ycs = vis_line.y0
				if (! vis_line.x0) {
					let last_vis_line = last_densened_vis_line_by_branch_id?.[branch_id]
					if (last_vis_line) {
						// Connect the line to the previous commit
						vis_line.x0 = last_vis_line.xn
						vis_line.xcs = vis_line.x0
						if (last_vis_line.y0 !== last_vis_line.yn) {
							// make curvy
							// So far, a line is simply defined as the connection between x0 and xn.
							// The lines all connect to each other. But between them, there is no curvature yet (hard edge).
							// Determining two control points near this junction:
							let last_xce = last_vis_line.x0 + (last_vis_line.xn - last_vis_line.x0) * (1 - curve_radius)
							let xcs = vis_line.x0 + (vis_line.xn - vis_line.x0) * curve_radius
							// ...and the strategy for creating a curve is to mark the control points fixed
							// but move the actual junction point's x toward the average between both control
							// points:
							let middle_x = (xcs + last_xce) / 2
							last_vis_line.xn = middle_x
							last_vis_line.xce = last_xce
							last_vis_line.yce = (last_vis_line.yn || 100) - curve_radius
							vis_line.x0 = middle_x
							vis_line.xcs = xcs
							vis_line.ycs = (vis_line.y0 || 100) + curve_radius
						}
					} else {
						// Nothing useful to connect to, probably a branch tip. Don't show anything
						// but store x/yn to be able to connect to it in next line
						vis_line.y0 = vis_line.ycs = vis_line.yn
						vis_line.x0 = vis_line.xcs = vis_line.xn
					}
				}
			}
			commits.push({
				index_in_graph_output: Number(row_no_s),
				vis_lines: Object.values(densened_vis_line_by_branch_id)
					// Leftmost branches should appear later so they are on top of the rest
					.sort((a, b) => (b.xcs || 0) + (b.xce || 0) - (a.xcs || 0) - (a.xce || 0)),
				branch: commit_branch,
				hash_long,
				hash,
				author_name,
				author_email,
				datetime,
				refs,
				subject,
			})

			last_densened_vis_line_by_branch_id = densened_vis_line_by_branch_id
			// Get rid of branches that "end" here (those that were born with this very commit)
			// as won't paint their lines anymore in future (= older) commits, *and*
			// get rid of collected connection lines - freshly start at this commit again
			densened_vis_line_by_branch_id = {}
		}
		last_vis = vis
	}
	for (let i = 1; i < commits.length; i++)
		for (let vis_line of commits[i].vis_lines) {
			if (vis_line.y0 === vis_line.yn)
				continue
			// Duplicate the line into the previous commit's lines because both rows
			// need to display it (each being only half-visible vertically)
			commits[i - 1].vis_lines.push({
				...vis_line,
				y0: (vis_line.y0 || 0) + 1,
				yn: (vis_line.yn || 0) + 1,
				ycs: (vis_line.ycs || 0) + 1,
				yce: (vis_line.yce || 0) + 1,
			})
		}

	// cannot do this at creation because branches list is not fixed before this (see "inferred substitute")
	for (let branch of branches)
		branch.color = (() => {
			switch (branch.name) {
				case 'master': case 'main': return '#ff3333'
				case 'development': case 'develop': case 'dev': return '#009000'
				case 'stage': case 'staging': case 'production': return '#d7d700'
				case 'HEAD': return '#ffffff'
				default:
					return colors[Math.abs(branch.name.hashCode() % colors.length)]
			}
		})()

	branches = branches.filter((branch) =>
		// these now reside linked inside vis objects (with colors), but don't mention them in the listing
		! branch.inferred,
	).sort(git_ref_sort)
		.slice(0, 10000)

	// stashes were queried (git reflog show stash) but shown as commits. Need to add refs:
	for (let stash of (stash_data || '').split('\n')) {
		// 7c37db63 stash@{11}
		let split = stash.split(' ')
		let commit = commits.find((c) => c.hash === split[0])
		let name = split.slice(1).join(' ')
		commit?.refs.push({
			name,
			id: name,
			type: 'stash',
			color: '#fff',
		})
	}

	return { commits, branches }
}
export { parse }
