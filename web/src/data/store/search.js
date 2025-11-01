import { ref, computed, watch } from 'vue'
import state from '../state.js'
import { push_history } from './history'
import * as repo_store from './repo.js'
import { trigger_main_refresh } from './index.js'
import quote_escape from '../../utils/quote-escape.js'

export let search_str = ref('')
export let type = state('search-type', 'jump').ref
export let is_regex = state('search-options-regex', false).ref
export let where = state('search-options-where', 'immediate').ref
watch([search_str, where], (_new, [old_search_str, old_where]) => {
	if (search_str.value)
		push_history({ type: 'search', value: search_str.value })
	if (search_str.value && where.value !== 'immediate')
		debounce(() => {
			if (! search_str.value || where.value === 'immediate')
				return
			let escaped = quote_escape(search_str.value)
			trigger_main_refresh({
				custom_log_args: ({ base_log_args }) =>
					`${base_log_args} ` + (where.value === 'file_contents'
						? `-n 1000 -S "${escaped}"` // middle ground to avoid hanging up everything in very large repos with rare search keys. TODO: set git execution timeout instead somehow
						: where.value === 'file_names'
							? `-n 5000 -- "*${escaped}*"`
							// body:
							: `-n 5000 --grep="${escaped}"`),
				fetch_stash_refs: false,
			})
		}, 1000)
	else if ((where.value !== 'immediate' && ! search_str.value && old_search_str) || (where.value === 'immediate' && old_where !== 'immediate'))
		trigger_main_refresh() // reset
})

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
export function commit_matches_immediate_search(/** @type {Commit} */ commit) {
	if (is_regex.value && ! regex.value)
		return false
	return [commit.subject, commit.hash_long, commit.author_name, commit.author_email, ...commit.refs.map((r) => r.id)]
		.some(str => str_index_of_search(str) > -1)
}
let filtered_commits = computed(() => {
	let all = repo_store.loaded_commits.value || []
	if (! search_str.value || type.value === 'jump' || where.value !== 'immediate')
		return all
	return (all).filter(commit_matches_immediate_search)
})

export let _protected = { filtered_commits }
