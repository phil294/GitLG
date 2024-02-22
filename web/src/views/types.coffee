import colors from "./colors.coffee"

###*
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
#	inferred?: boolean
# }} Branch
#
# @typedef {{
#	branch?: Branch | undefined
#	x0: number
#	y0?: number
#	xn: number
#	yn?: number
#	xcs?: number
#	ycs?: number
#	xce?: number
#	yce?: number
# }} VisLine
# Vis chars are transformed by us into vis lines (as in: a svg line) that have an
# `x0` and an `x1` "coordinate" (from / to). These coordinates will have to be mapped
# to the actual svg grid as there is no spacing here yet.
# Every commit will have at least one vis line.
# For what `x0`, `ycs` and so on stand for, please refer to the documentation at
# https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#cubic_b%C3%A9zier_curve
#
# @typedef {{
#	i: number
#	vis_lines: VisLine[]
#	branch?: Branch
#	hash: string
#	hash_long: string
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
#
# @typedef {{
#	type: 'txt_filter' | 'branch_id' | 'commit_hash' | 'git'
#	value: string
#	datetime: string
# }} HistoryEntry
###

###*
# To use in place of `.filter(Boolean)` for type safety with strict null checks.
# @template T
# @param value {T | undefined | null | false}
# @return {value is T}
###
export is_truthy = (value) => !!value

###* @return {ref is Branch} ###
export is_branch = (###* @type {GitRef} ### ref) =>
	ref.type == "branch"