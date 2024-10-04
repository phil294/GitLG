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
	 * @param options {{ remote_name?: string, tracking_remote_name?: string, is_inferred?: boolean, name_may_include_remote?: boolean}}=
	 */
	function new_branch(name, { remote_name, tracking_remote_name, is_inferred, name_may_include_remote } = {}) {
		if (name_may_include_remote && ! remote_name && name.includes('/')) {
			let split = name.split('/')
			name = split.at(-1) || ''
			remote_name = split.slice(0, split.length - 1).join('/')
		}
		/** @type {Branch} */
		let branch = {
			name,
			color: undefined,
			type: 'branch',
			remote_name,
			tracking_remote_name,
			id: (remote_name ? `${remote_name}/${name}` : name) + (is_inferred ? '~' + (branches.length - 1) : ''),
			inferred: is_inferred,
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
			/**
			 * Parsing from top to bottom (reverse chronologically). The flow is
			 * generally rtl horizontally. So for example, the "/" char would direct the
			 * branch line from top right to bottom left and thus yield a {x0:1,xn:0} vis line,
			 * with y0=0 and yn=1 either way (unless specified otherwise)
			 * @type {VisLine}
			 */
			let vis_line = { x0: 0, xn: 0 }
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
						// Stashes
						v_branch = new_branch('inferred', { is_inferred: true })

					commit_branch = v_branch || undefined
					vis_line = { x0: 0.5, xn: 0.5 }
					if (! last_vis[i] || ! last_vis[i].char || last_vis[i].char === ' ')
						// Branch or inferred branch starts here visually (ends here logically)
						vis_line.y0 = 0.5
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
					vis_line = { x0: 0.5, xn: 0.5, yn: 0.5 }
					break
				case '_':
					v_branch = v_ee?.branch
					vis_line = { x0: 1, xn: 0 }
					break
				case '/':
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
					// Straight line. Looks better this way idk. Also significant change yn=0.5
					// to avoid branch birth lines to appear before their birth commit circle
					vis_line = { x0: 1, y0: 0, xn: -0.5, yn: 0.5, xcs: 0.25, xce: 0.25, ycs: 0.25, yce: 0.25 }
					break
				case '\\':
					vis_line = { x0: -0.5, xn: 1 }
					if (v_w_char === '|') {
						// right below a merge commit (which would be at v_nw).
						let last_commit = commits.at(-1)
						if (v_e?.char === '|' && v_e?.branch) {
							// Actually the very same branch as v_e, but the densened_vis_line logic can only handle one line per branch at a time.
							v_branch = new_branch(v_e.branch.id, { is_inferred: true, name_may_include_remote: true })
							// And because this is now a new one, it won't be joined together with the follow-up branch lines
							// so the positioning needs to be done entirely here
							vis_line = { x0: -0.5, xn: 1.5, yn: 0.5, yce: 0.5, xcs: 1.5 }
						} else {
							// The actual branch name isn't known for sure yet: It will either a.) be visible with a branch tip
							// in the next commit or never directly exposed, in which case we'll b.) try to infer it from the
							// merge commit message, or if failing to do so, c.) create an inferred branch without name.
							// b.) and c.) will be overwritten again if a.) occurs [see "inferred substitute"].
							let subject_merge_match = last_commit?.subject.match(/^Merge (?:(?:remote[ -]tracking )?branch '([^ ]+)'.*)|(?:pull request #[0-9]+ from (.+))$/)
							if (subject_merge_match)
								v_branch = new_branch(subject_merge_match[1] || subject_merge_match[2], { is_inferred: true, name_may_include_remote: true })
							else
								v_branch = new_branch('', { is_inferred: true })
						}
						if (last_commit) {
							last_commit.merge = true
							// Retroactively adjust vis lines so that the merge appears to go upwards into the merge commit circle,
							// not at the line before. This is like setting y0=-0.6 to *this* vis_line which isn't possible
							// due to the commit row encapsulation.
							let new_last_commit_vis_line = { branch: v_branch, x0: i - 1 + 0.5, xn: i - 1 + 0.5, xcs: i - 1 + 0.5, y0: 0.4, yn: 1, ycs: 0.75 }
							last_commit.vis_lines.push(new_last_commit_vis_line)
							last_densened_vis_line_by_branch_id[v_branch.id] = new_last_commit_vis_line
						}
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

			if (v_branch) {
				vis_line.x0 += i
				vis_line.xn += i
				if (vis_line.xcs != null)
					vis_line.xcs += i
				if (vis_line.xce != null)
					vis_line.xce += i
				if (densened_vis_line_by_branch_id[v_branch.id]) {
					densened_vis_line_by_branch_id[v_branch.id].xn = vis_line.xn
					densened_vis_line_by_branch_id[v_branch.id].xce = vis_line.xce
					densened_vis_line_by_branch_id[v_branch.id].yn = vis_line.yn
					densened_vis_line_by_branch_id[v_branch.id].yce = vis_line.yce
				} else {
					vis_line.branch = v_branch
					densened_vis_line_by_branch_id[v_branch.id] = vis_line
				}
			}
		}
		if (subject) {
			// After 1-n parsed rows, we have now arrived at what will become one row
			// in *our* application too.
			for (let [branch_id, vis_line] of Object.entries(densened_vis_line_by_branch_id)) {
				if (vis_line.y0 == null)
					vis_line.y0 = 0
				if (vis_line.yn == null)
					vis_line.yn = 1
				if (vis_line.xce == null)
					// We don't know yet if this line is the last one of rows for this branch
					// or if more will be to come. The latter case is handled later, so for the former
					// case to look nice, some downwards angle is added by default by moving the end
					// control point upwards. This makes sense because the last line is the birth
					// spot and branches are always based on another branch, so this draws an
					// upwards splitting effect
					vis_line.xce = vis_line.xn
				if (vis_line.yce == null)
					vis_line.yce = 1 - curve_radius / 2 // Must not be too strong
				// Make connection to previous row's branch line curvy?
				let last_vis_line = last_densened_vis_line_by_branch_id?.[branch_id]
				if (last_vis_line) {
					// So far, a line is simply defined as the connection between x0 and xn with
					// y0 and y1 being 0 and 1, respectively. The lines all connect to each
					// other. But between them, there is no curvature yet (hard edge).
					// Determining two control points near this junction:
					// (see VisLine JSDoc for naming info)
					let last_xce = last_vis_line.x0 + (last_vis_line.xn - last_vis_line.x0) * (1 - curve_radius)
					let xcs = vis_line.x0 + (vis_line.xn - vis_line.x0) * curve_radius
					// ...and the strategy for creating a curve is to mark the control points fixed
					// but move the actual junction point's x toward the average between both control
					// points:
					let middle_x = (xcs + last_xce) / 2
					last_vis_line.xn = middle_x
					last_vis_line.xce = last_xce
					last_vis_line.yce = 1 - curve_radius
					last_vis_line.yn = 1
					vis_line.x0 = middle_x
					vis_line.xcs = xcs
					vis_line.ycs = curve_radius
				} else {
					if (vis_line.xcs == null)
						// First time this branch appeared
						if (vis_line.xn > vis_line.x0)
							// so we want an upwards curvature, just like
							// the logic around initializing xce above, but reversed:
							vis_line.xcs = vis_line.x0 + 1
						else
							vis_line.xcs = vis_line.x0
					vis_line.ycs = curve_radius
				}
			}
			commits.push({
				i: Number(row_no_s),
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
