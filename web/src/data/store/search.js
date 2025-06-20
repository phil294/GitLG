import { ref, computed, watch } from 'vue'
import state from '../state.js'
import { push_history } from './history'
import * as repo_store from './repo.js'

export let search_str = ref('')
watch(search_str, () => {
	if (search_str.value)
		push_history({ type: 'search', value: search_str.value })
})

export let type = state('search-type', /** @type {'filter' | 'jump'} */ ('jump')).ref
export let is_regex = state('search-options-regex', false).ref
let regex = computed(() =>
	search_str.value && is_regex.value
		? (() => { try { return new RegExp(search_str.value, 'i') } catch (_) { return null } })()
		: null,
)
export function str_index_of_search(/** @type {string} */ str) {
	return regex.value
		? str.toLowerCase().match(regex.value)?.index ?? -1
		: str.toLowerCase().indexOf(search_str.value.toLowerCase())
}
export function commit_matches_search(/** @type {Commit} */ commit) {
	if (is_regex.value && ! regex.value)
		return false
	return [commit.subject, commit.hash_long, commit.author_name, commit.author_email, ...commit.refs.map((r) => r.id)]
		.some(str => str_index_of_search(str) > -1)
}
let filtered_commits = computed(() => {
	let all = repo_store.loaded_commits.value || []
	if (! search_str.value || type.value === 'jump')
		return all
	return (all).filter(commit_matches_search)
})

export let _protected = { filtered_commits }
