import colors from "./colors.coffee"

``###*
# @typedef {{
#	name: string
#	color?: colors[number]
#	type: "tag" | "stash" | "branch"
# }} GitRef
# @typedef {GitRef & {
#	type: "branch"
#	virtual?: boolean
# }} Branch
#
# @typedef {{
#	char: string
#	branch: Branch | null
# }[]} Vis
#
# @typedef {{
#	i: number
#	vis: Vis
#	branch?: Branch
#	hash: string
#	author_name: string
#	author_email: string
#	datetime?: string
#	refs: GitRef[]
#	subject: string
#	stats?: {
#		files_changed?: number
#		insertions?: number
#		deletions?: number
#	}
#	scroll_height: number
# }} Commit
#
# @typedef {{
#	value: string
#	default_active: boolean
#	active?: boolean
# }} GitOption
#
# @typedef {{
#	title: string
#	description?: string
#	immediate?: boolean
#	ignore_errors:? boolean
#	args: string
#	params?: string[]
#	options?: GitOption[]
#	icon?: string
# }} ConfigGitAction
#
# @typedef {ConfigGitAction & {
#	config_key: string
# }} GitAction
###

export {}