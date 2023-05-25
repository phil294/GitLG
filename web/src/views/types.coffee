import colors from "./colors.coffee"

``###*
# @typedef {{
#	name: string
#	id: string
#	color?: colors[number]
#	type: "tag" | "stash" | "branch"
# }} GitRef
# @typedef {GitRef & {
#	type: "branch"
#	remote_name?: string
#	tracking_remote_name?: string
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
#	merge?: boolean
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

``###*
# To use in place of `.filter(Boolean)` for type safety with strict null checks.
# @template T
# @param value {T | undefined | null | false}
# @return {value is T}
###
export is_truthy = (value) => !!value
