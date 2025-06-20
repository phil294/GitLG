import { ref, computed, watch } from 'vue'
import state from '../state.js'
import { push_history } from './history'
import * as repo_store from './repo.js'

export let filter_str = ref('')
watch(filter_str, () => {
	if (filter_str.value)
		push_history({ type: 'txt_filter', value: filter_str.value })
})

export let type = state('filter-type', /** @type {'filter' | 'jump'} */ ('jump')).ref
export let is_regex = state('filter-options-regex', false).ref
let regex = computed(() =>
	filter_str.value && is_regex.value
		? (() => { try { return new RegExp(filter_str.value, 'i') } catch (_) { return null } })()
		: null,
)
// TODO: naming
export function str_index_of_filter(/** @type {string} */ str) {
	return regex.value
		? str.toLowerCase().match(regex.value)?.index ?? -1
		: str.toLowerCase().indexOf(filter_str.value.toLowerCase())
}
export function commit_matches_filter(/** @type {Commit} */ commit) {
	if (is_regex.value && ! regex.value)
		return false
	return [commit.subject, commit.hash_long, commit.author_name, commit.author_email, ...commit.refs.map((r) => r.id)]
		.some(str => str_index_of_filter(str) > -1)
}
let filtered_commits = computed(() => {
	let all = repo_store.loaded_commits.value || []
	if (! filter_str.value || type.value === 'jump')
		return all
	return (all).filter(commit_matches_filter)
})

export let _protected = { filtered_commits }
