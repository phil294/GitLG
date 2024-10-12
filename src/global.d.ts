import Vue = GlobalImports.Vue

interface String {
	hashCode(): number
}

interface Function {
	/** Call *this* with *args* and silently return `undefined` on error. */
	maybe<T>(this: (...fun_args: any[]) => T, ...call_args: any): T | undefined
}

interface Promise<T> {
	/** Catch and ignore. Like `.catch(() => undefined)`. */
	maybe(): Promise<T | undefined>
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
	id: string
	color?: typeof import('../web/src/utils/colors.js')[number]
	type: "tag" | "stash" | "branch"
}

interface Branch extends GitRef {
	type: "branch"
	remote_name?: string
	/** For display of multiple remotes inside one Ref */
	remote_names_group?: string[]
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
	stats?: {
		files_changed: number
		insertions: number
		deletions: number
	}
}

interface GitOption {
	value: string
	default_active: boolean
	active?: boolean
	info?: string
}

interface ConfigGitAction {
	title: string
	description?: string
	info?: string
	immediate?: boolean
	ignore_errors?: boolean
	args: string
	params?: string[]
	options?: GitOption[]
	icon?: string
}

interface GitAction extends ConfigGitAction {
	config_key: string
}

interface HistoryEntry {
	type: 'txt_filter' | 'branch_id' | 'commit_hash' | 'git'
	value: string
	datetime?: string
}