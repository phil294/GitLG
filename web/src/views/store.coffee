import { ref, computed, shallowRef } from "vue"
import default_git_actions from './default-git-actions.json'
import { parse } from "./log-utils.coffee"
import { git, exchange_message, add_push_listener } from "../bridge.coffee"
import { parse_config_actions } from "./GitInput.coffee"
import GitInputModel from './GitInput.coffee'
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
###* @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef ###

#########################
# This file should be used for state that is of importance for more than just one component.
# It encompasses state, actions and getters (computed values).
#########################

``###* @type {Record<string, WritableComputedRef<any>>} ###
_stateful_computeds = {}
add_push_listener 'state-update', ({ data: { key, value } }) =>
	if _stateful_computeds[key]
		_stateful_computeds[key].value = value
``###* @template T
# This utility returns a `WritableComputed` that will persist its state or react to changes on the
# backend somehow. The caller doesn't know where it's stored though, this is up to extension.coffee
# to decide based on the *key*.
###
export stateful_computed = (###* @type {string} ### key, ###* @type {T} ### default_value, ###* @type {()=>any} ### on_load) =>
	``###* @type {WritableComputedRef<T>|undefined} ###
	ret = _stateful_computeds[key]
	if ret
		do on_load
		return ret
	# shallow because type error https://github.com/vuejs/composition-api/issues/483
	internal = shallowRef default_value
	ret = computed
		get: => internal.value
		set: (###* @type {T} ### value) =>
			if internal.value != value
				exchange_message 'set-state', { key, value }
			internal.value = value
	_stateful_computeds[key] = ret
	do =>
		stored = await exchange_message 'get-state', key
		if stored?
			internal.value = stored # to skip the unnecessary roundtrip to backend
			ret.value = stored
		on_load?()
	ret

``###* @type {Ref<Commit[]|null>} ###
export commits = ref null

``###* @type {Ref<Branch[]>} ###
export branches = ref []
# this is either a branch id(name) or HEAD in which case it will simply not be shown
# which is also not necessary because HEAD is then also visible as a branch tip.
export head_branch = ref ''
export vis_max_amount = ref 0
export git_status = ref ''
###* @type {Ref<string|null>} ###
export default_origin = ref ''

export git_run_log = (###* @type string ### log_args) =>
	sep = '^%^%^%^%^'
	log_args = log_args.replace(" --pretty={EXT_FORMAT}", " --pretty=format:\"#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s\"")
	stash_refs = try await git 'reflog show --format="%h" stash' catch then ""
	log_args = log_args.replace("{STASH_REFS}", stash_refs.replaceAll('\n', ' '))
	# errors will be handled by GitInput
	[ log_data, branch_data, stash_data, status_data, head_data ] = await Promise.all [
		git log_args
		git "branch --list --all --format=\"%(upstream:remotename)#{sep}%(refname)\""
		try await git "stash list --format=\"%h %gd\""
		git 'status'
		git 'rev-parse --abbrev-ref HEAD'
	]
	return if not log_data?
	parsed = parse log_data, branch_data, stash_data, sep
	commits.value = parsed.commits
	branches.value = parsed.branches
	vis_max_amount.value = parsed.vis_max_amount
	head_branch.value = head_data
	git_status.value = status_data
	likely_default_branch = (branches.value.find (b) => b.name=='master'||b.name=='main') || branches.value[0]
	default_origin.value = likely_default_branch?.remote_name or likely_default_branch?.tracking_remote_name or null
``###* @type {Ref<Ref<GitInputModel|null>|null>} ###
export main_view_git_input_ref = ref null
export refresh_main_view = =>
	console.warn('refreshing main view')
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

``###* @type {Ref<GitAction|null>} ###
export selected_git_action = ref null

``###* @type {Ref<any>} ###
export config = ref {}
export refresh_config = =>
	config.value = await exchange_message 'get-config'

``###* @type {Ref<ConfigGitAction[]>} ###
export global_actions = computed =>
	default_git_actions['actions.global'].concat(config.value.actions?.global or [])
export commit_actions = (###* @type string ### hash) => computed =>
	config_commit_actions = default_git_actions['actions.commit'].concat(config.value.actions?.commit or [])
	parse_config_actions(config_commit_actions, [['{COMMIT_HASH}', hash]])
export commits_actions = (###* @type string[] ### hashes) => computed =>
	config_commits_actions = default_git_actions['actions.commits'].concat(config.value.actions?.commits or [])
	parse_config_actions(config_commits_actions, [['{COMMIT_HASHES}', hashes.join(' ')]])
export branch_actions = (###* @type Branch ### branch) => computed =>
	config_branch_actions = default_git_actions['actions.branch'].concat(config.value.actions?.branch or [])
	parse_config_actions(config_branch_actions, [
		['{BRANCH_NAME}', branch.id]
		['{LOCAL_BRANCH_NAME}', branch.name]
		['{REMOTE_NAME}', branch.remote_name or branch.tracking_remote_name or default_origin.value or 'MISSING_REMOTE_NAME']])
export tag_actions = (###* @type string ### tag_name) => computed =>
	config_tag_actions = default_git_actions['actions.tag'].concat(config.value.actions?.tag or [])
	parse_config_actions(config_tag_actions, [['{TAG_NAME}', tag_name]])
export stash_actions = (###* @type string ### stash_name) => computed =>
	config_stash_actions = default_git_actions['actions.stash'].concat(config.value.actions?.stash or [])
	parse_config_actions(config_stash_actions, [['{STASH_NAME}', stash_name]])
export combine_branches_actions = computed =>
	config_combine_branches_actions = default_git_actions['actions.branch-drop'].concat(config.value.actions?['branch-drop'] or [])
	parse_config_actions(config_combine_branches_actions, [
		['{SOURCE_BRANCH_NAME}', combine_branches_from_branch_name.value]
		['{TARGET_BRANCH_NAME}', combine_branches_to_branch_name.value]])

export combine_branches_to_branch_name = ref ''
export combine_branches_from_branch_name = ref ''
export combine_branches = (###* @type string ### from_branch_name, ###* @type string ### to_branch_name) =>
	return if from_branch_name == to_branch_name
	combine_branches_to_branch_name.value = to_branch_name
	combine_branches_from_branch_name.value = from_branch_name

export vis_v_width = computed =>
	if not config.value['branch-width'] or not Number(config.value['branch-width'])
		# Linear drop from 10 to 2
		Math.max(1, Math.min(10, Math.round(vis_max_amount.value * (-1) * 8 / 50 + 18)))
	else
		Number(config.value['branch-width'])

export init = =>
	refresh_config()

	add_push_listener 'config-change', =>
		await refresh_config()
		refresh_main_view()

	add_push_listener 'repo-external-state-change', refresh_main_view