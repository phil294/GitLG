import { parse_config_actions } from "./GitInput.coffee"
import { parse } from "./log-utils.coffee"
import { git, get_config } from "../bridge.coffee"
import GitInputModel from './GitInput.coffee'
import { ref, computed } from "vue"
``###*
# @typedef {import('./types').GitRef} GitRef
# @typedef {import('./types').Branch} Branch
# @typedef {import('./types').Vis} Vis
# @typedef {import('./types').Commit} Commit
# @typedef {import('./types').ConfigGitAction} ConfigGitAction
# @typedef {import('./types').GitAction} GitAction
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###
###* @template T @typedef {import('vue').ComputedRef<T>} ComputedRef ###

#########################
# This file should be used for state that is likely of importance for more than just one component.
# It encompasses state, actions and getters (computed values).
#########################

``###* @type {Ref<Commit[]|null>} ###
export commits = ref null

``###* @type {Ref<Branch[]>} ###
export branches = ref []
# this is either a branch name or HEAD in which case it will simply not be shown
# which is also not necessary because HEAD is then also visible as a branch tip.
export head_branch = ref ''
export vis_max_length = ref 0

export git_run_log = (###* @type string ### log_args) =>
	sep = '^%^%^%^%^'
	log_args = log_args.replace(" --pretty=VSCode", " --pretty=format:\"#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s\"")
	stash_refs = try await git 'reflog show --format="%h" stash' catch then ""
	log_args = log_args.replace("stash_refs", stash_refs.replaceAll('\n', ' '))
	# errors will be handled by GitInput
	[ log_data, stash_data ] = await Promise.all [
		git log_args
		try await git 'stash list --format="%h %gd"'
	]
	return if not log_data
	parsed = parse log_data, sep
	# stashes are queried (git reflog show stash) but shown as commits. Need to add refs:
	for stash from (stash_data or '').split('\n')
		# 7c37db63 stash@{11}
		split = stash.split(' ')
		commit = parsed.commits.find((c) => c.hash == split[0])
		commit?.refs.push
			name: split.slice(1).join(' ')
			type: "stash"
			color: '#fff'
	commits.value = parsed.commits
	branches.value = parsed.branches
	# todo rename to vis_max_amount
	vis_max_length.value = parsed.vis_max_length
	head_branch.value = await git 'rev-parse --abbrev-ref HEAD'
``###* @type {Ref<Ref<GitInputModel|null>|null>} ###
export main_view_git_input_ref = ref null
export refresh_main_view = =>
	console.info('refreshing main view')
	main_view_git_input_ref.value?.value?.execute()

export update_commit_stats = (###* @type {Commit[]} ### commits) =>
	data = await git "show --format=\"%h\" --shortstat " + commits.map((c)=>c.hash).join(' ')
	return if not data
	hash = ''
	for line from data.split('\n').filter(Boolean)
		if not line.startsWith ' '
			hash = line
			continue
		stat = files_changed: 0, insertions: 0, deletions: 0
		#  3 files changed, 87 insertions(+), 70 deletions(-)
		for stmt from line.trim().split(', ')
			words = stmt.split(' ')
			if words[1].startsWith 'file'
				stat.files_changed = Number(words[0])
			else if words[1].startsWith 'insertion'
				stat.insertions = Number(words[0])
			else if words[1].startsWith 'deletion'
				stat.deletions = Number(words[0])
		commits[commits.findIndex((cp)=>cp.hash==hash)].stats = stat

``###* @type {Ref<ConfigGitAction[]>} ###
export global_actions = ref []
``###* @type {Ref<ConfigGitAction[]>} ###
config_branch_actions = ref []
export commit_actions = (###* @type string ### hash) =>
	parse_config_actions(config_commit_actions.value, [['{COMMIT_HASH}', hash]])
``###* @type {Ref<ConfigGitAction[]>} ###
config_commit_actions = ref []
export branch_actions = (###* @type string ### branch_name) =>
	parse_config_actions(config_branch_actions.value, [['{BRANCH_NAME}', branch_name]])
``###* @type {Ref<ConfigGitAction[]>} ###
config_stash_actions = ref []
export stash_actions = (###* @type string ### hash) =>
	parse_config_actions(config_stash_actions.value, [['{COMMIT_HASH}', hash]])
``###* @type {Ref<ConfigGitAction[]>} ###
_unparsed_combine_branches_actions = ref []
export combine_branches_actions = computed =>
	parse_config_actions(_unparsed_combine_branches_actions.value, [
		['{SOURCE_BRANCH_NAME}', combine_branches_from_branch_name.value],
		['{TARGET_BRANCH_NAME}', combine_branches_to_branch_name.value]])

export combine_branches_to_branch_name = ref ''
export combine_branches_from_branch_name = ref ''
export combine_branches = (###* @type string ### from_branch_name, ###* @type string ### to_branch_name) =>
	return if from_branch_name == to_branch_name
	combine_branches_to_branch_name.value = to_branch_name
	combine_branches_from_branch_name.value = from_branch_name

``###* @type {Ref<GitAction|null>} ###
export selected_git_action = ref null

``###* @type {Ref<Commit|null>} ###
export selected_commit = ref null

``###* @type {Ref<number|string>} ###
export config_width = ref ''

export init = =>
	refresh_config()
export refresh_config = =>
	global_actions.value = await get_config 'actions.global'
	config_branch_actions.value = await get_config 'actions.branch'
	config_commit_actions.value = await get_config 'actions.commit'
	config_stash_actions.value = await get_config 'actions.stash'
	
	_unparsed_combine_branches_actions.value = await get_config 'actions.branch-drop'

	config_width.value = await get_config 'branch-width'

export vis_v_width = computed =>
	if not config_width.value or not Number(config_width.value)
		Math.max(2, Math.min(10, Math.round(vis_max_length.value * (-1) * 8 / 50 + 18)))
	else
		Number(config_width.value)