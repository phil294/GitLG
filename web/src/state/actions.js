import { computed } from 'vue'
import default_git_actions from './default-git-actions.json'
import { combine_branches_from_branch_name, combine_branches_to_branch_name, config, default_origin } from './store'

/**
 * @param actions {ConfigGitAction[]}
 * @param replacements {[string,string][]}
 * @returns {GitAction[]}
 */
function parse_config_actions(actions, replacements = []) {
	let namespace = replacements.map(([k]) => k).join('-') || 'global'
	function do_replacements(/** @type {string} */ txt) {
		for (let replacement of replacements)
			txt = txt.replaceAll(replacement[0], replacement[1])
		return txt
	}
	return actions.map((action) => ({
		...action,
		title: do_replacements(action.title),
		description: action.description ? do_replacements(action.description) : undefined,
		config_key: `action-${namespace}-${action.title}`,
		params: action.params?.map(do_replacements),
	}))
}

/** @type {Vue.Ref<ConfigGitAction[]>} */
export let global_actions = computed(() =>
	parse_config_actions(default_git_actions['actions.global'].concat(config.value.actions?.global || [])))
export let commit_actions = (/** @type {string} */ hash) => computed(() => {
	let config_commit_actions = default_git_actions['actions.commit'].concat(config.value.actions?.commit || [])
	return parse_config_actions(config_commit_actions, [
		['{COMMIT_HASH}', hash],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let commits_actions = (/** @type {string[]} */ hashes) => computed(() => {
	let config_commits_actions = default_git_actions['actions.commits'].concat(config.value.actions?.commits || [])
	return parse_config_actions(config_commits_actions, [
		['{COMMIT_HASHES}', hashes.join(' ')],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let branch_actions = (/** @type {Branch} */ branch) => computed(() => {
	let config_branch_actions = default_git_actions['actions.branch'].concat(config.value.actions?.branch || [])
	return parse_config_actions(config_branch_actions, [
		['{BRANCH_ID}', branch.id],
		['{BRANCH_DISPLAY_NAME}', branch.display_name],
		['{BRANCH_NAME}', branch.name],
		['{LOCAL_BRANCH_NAME}', branch.remote_name ? /** User intervention required */ '' : branch.name],
		['{REMOTE_NAME}', branch.remote_name || branch.tracking_remote_name || default_origin.value || 'MISSING_REMOTE_NAME'],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let tag_actions = (/** @type {string} */ tag_name) => computed(() => {
	let config_tag_actions = default_git_actions['actions.tag'].concat(config.value.actions?.tag || [])
	return parse_config_actions(config_tag_actions, [
		['{TAG_NAME}', tag_name],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let stash_actions = (/** @type {string} */ stash_name) => computed(() => {
	let config_stash_actions = default_git_actions['actions.stash'].concat(config.value.actions?.stash || [])
	return parse_config_actions(config_stash_actions, [
		['{STASH_NAME}', stash_name],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
export let combine_branches_actions = computed(() => {
	let config_combine_branches_actions = default_git_actions['actions.branch-drop'].concat(config.value.actions?.['branch-drop'] || [])
	return parse_config_actions(config_combine_branches_actions, [
		['{SOURCE_BRANCH_NAME}', combine_branches_from_branch_name.value],
		['{TARGET_BRANCH_NAME}', combine_branches_to_branch_name.value],
		['{DEFAULT_REMOTE_NAME}', default_origin.value || 'MISSING_REMOTE_NAME']])
})
