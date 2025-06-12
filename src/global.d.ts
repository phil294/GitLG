import Vue = GlobalImports.Vue

interface String {
	hashCode(): number
}

interface BridgeMessage {
	type: 'response-to-web' | 'request-from-web' | 'push-to-web',
	command?: string,
	data?: any,
	error?: any,
	id: number | string
}

interface GitRef {
	name: string
	/**
	 * Begins with `refs/heads/` or `refs/remotes/` or `refs/tags/` for actual git refs
	 * or `inferred~` for gitlg-specific inferred ones
	 */
	id: string
	/** Same way git log shows them. Note that there can be duplicate *display_name*s, see `name` */
	display_name: string
	color?: typeof import('../web/src/utils/colors.js')[number]
	type: "tag" | "stash" | "branch"
}

interface Branch extends GitRef {
	/**
	 * The full name without the remote, e.g. for id `refs/remotes/origin/master` it would be
	 * `master`. Branch names may contain slashes, so for something contorted such as
	 * `refs/heads/origin/master`, *name* would be `origin/master` where `origin` does *not* refer
	 * to a remote.
	 */
	name: string
	type: "branch"
	/** e.g. `origin` */
	remote_name?: string
	/** For display of multiple remotes inside one Ref */
	remote_names_group?: string[]
	/** e.g. `origin`. For non-remote branches. */
	tracking_remote_name?: string
	inferred?: boolean
}

/**
 * Vis chars are transformed by us into vis lines (as in: a svg line) that have an
 * `x0` and an `x1` "coordinate" (from / to). These coordinates will have to be mapped
 * to the actual svg grid as there is no spacing here yet.
 * Every commit will have at least one vis line.
 * For what `x0`, `ycs` and so on stand for, please refer to the documentation at
 * https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#cubic_b%C3%A9zier_curve
 */
interface VisLine {
	branch?: Branch | undefined
	x0: number
	y0?: number
	xn: number
	yn?: number
	xcs?: number
	ycs?: number
	xce?: number
	yce?: number
}

interface Commit {
	index_in_graph_output: number
	vis_lines: VisLine[]
	branch?: Branch
	hash: string
	hash_long: string
	author_name: string
	author_email: string
	datetime?: string
	refs: GitRef[]
	subject: string
	merge?: boolean
	/** undefined means not yet queried, an empty object signifies a loading state,
	only files_changed present means it went through name stats already and
	full properties come after full retrieval  */
	stats?: {
		files_changed?: number
		insertions?: number
		deletions?: number
	}
}

interface GitOption {
	value: string
	default_active: boolean
	active?: boolean
	info?: string
}

interface GitActionParam {
	value: string
	multiline?: boolean
	placeholder?: string
	readonly?: boolean
}

interface ConfigGitAction {
	title: string
	description?: string
	info?: string
	immediate?: boolean
	ignore_errors?: boolean
	args: string
	params?: Array<string | GitActionParam>
	options?: GitOption[]
	icon?: string
}

interface GitAction extends ConfigGitAction {
	/** Set empty string to disable */
	storage_key: string
	params: () => Promise<GitActionParam[]>
}

interface HistoryEntry {
	type: 'txt_filter' | 'branch_id' | 'commit_hash' | 'git'
	value: string
	datetime?: string
}