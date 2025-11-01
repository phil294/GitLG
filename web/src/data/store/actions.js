import { computed } from 'vue'
import default_git_actions from '../default-git-actions.json'
import { combine_branches_from_branch_name, combine_branches_to_branch_name } from '../store'
import { git } from '../../bridge'
import { default_origin } from '../store/repo'
import config from '../store/config'

/**
 * @param actions {ConfigGitAction[]}
 * @param replacements {[string,string|(()=>Promise<string>)][]}
 * @returns {GitAction[]}
 */
function apply_action_replacements(actions, replacements = []) {
	let namespace = replacements.map(([k]) => k).join('-') || 'global'
	let replacements_by_type = replacements.reduce((all, replacement) =>
		/** tsc doesn't understand any of this */ ((/** @type {any} */ (all)[typeof replacement[1]] ??= []).push(replacement), all), /** @type {{string:[string,string][], function:[string,()=>Promise<string>][]}} */ ({ string: [], function: [] }))
	let apply_string_replacements = (/** @type {string} */ txt) =>
		replacements_by_type.string.reduce((str, replacement) =>
			str.replaceAll(replacement[0], replacement[1]), txt)
	let apply_promise_replacements = async (/** @type {string} */ txt) =>
		replacements_by_type.function.reduce(async (str_promise, replacement) =>
			! txt.includes(replacement[0]) ? str_promise
				: (await str_promise).replaceAll(replacement[0], await replacement[1]())
		, Promise.resolve(txt))
	return actions.map(action => ({
		...action,
		title: apply_string_replacements(action.title),
		description: apply_string_replacements(action.description || ''),
		// This should better also include the action placement (global, branch, stash, ...),
		// also 'global' vs. replacements doesn't make any sense in namespace.
		// But changing this would now break existing configs, so a migration or change logic
		// based on installation date would be required...
		storage_key: `action-${namespace}-${action.title || action.icon}`,
		params: () => Promise.all((action.params || [])
			.map(p => typeof p === 'string' ? { value: p } : p)
			.map(p => ({ ...p, value: apply_string_replacements(p.value) }))
			.map(p => apply_promise_replacements(p.value).then(value => ({ ...p, value })))),
	}))
}

/** @type {Vue.Ref<GitAction[]>} */
export let global_actions = computed(() =>
	apply_action_replacements(/** @type {ConfigGitAction[]} */ (default_git_actions['actions.global'])
		.concat(config.get_git_actions('actions.global'))))
export let commit_actions = (/** @type {string} */ hash) => computed(() => {
	let config_commit_actions = /** @type {ConfigGitAction[]} */ (default_git_actions['actions.commit'])
		.concat(config.get_git_actions('actions.commit'))
	return apply_action_replacements(config_commit_actions, [
		['{COMMIT_HASH}', hash],
		['{COMMIT_BODY}', () =>
			git(`show -s --format="%B" ${hash}`)],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let commits_actions = (/** @type {string[]} */ hashes) => computed(() => {
	let config_commits_actions = /** @type {ConfigGitAction[]} */ (default_git_actions['actions.commits'])
		.concat(config.get_git_actions('actions.commits'))
	return apply_action_replacements(config_commits_actions, [
		['{COMMIT_HASHES}', hashes.join(' ')],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let branch_actions = (/** @type {Branch} */ branch) => computed(() => {
	let config_branch_actions = /** @type {ConfigGitAction[]} */ (default_git_actions['actions.branch'])
		.concat(config.get_git_actions('actions.branch'))
	return apply_action_replacements(config_branch_actions, [
		['{BRANCH_ID}', branch.id],
		['{BRANCH_DISPLAY_NAME}', branch.display_name],
		['{BRANCH_NAME}', branch.name],
		['{LOCAL_BRANCH_NAME}', branch.remote_name ? /** User intervention required */ '' : branch.name],
		['{REMOTE_NAME}', branch.remote_name || branch.tracking_remote_name || default_origin.value || 'MISSING_REMOTE_NAME'],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let tag_actions = (/** @type {string} */ tag_name) => computed(() => {
	let config_tag_actions = /** @type {ConfigGitAction[]} */ (default_git_actions['actions.tag'])
		.concat(config.get_git_actions('actions.tag'))
	return apply_action_replacements(config_tag_actions, [
		['{TAG_NAME}', tag_name],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let stash_actions = (/** @type {string} */ stash_name) => computed(() => {
	let config_stash_actions = /** @type {ConfigGitAction[]} */ (default_git_actions['actions.stash'])
		.concat(config.get_git_actions('actions.stash'))
	return apply_action_replacements(config_stash_actions, [
		['{STASH_NAME}', stash_name],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let combine_branches_actions = computed(() => {
	let config_combine_branches_actions = /** @type {ConfigGitAction[]} */ (default_git_actions['actions.branch-drop'])
		.concat(config.get_git_actions('actions.branch-drop'))
	return apply_action_replacements(config_combine_branches_actions, [
		['{SOURCE_BRANCH_NAME}', combine_branches_from_branch_name.value],
		['{TARGET_BRANCH_NAME}', combine_branches_to_branch_name.value],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
