import state from '../../data/state'
import { push_history } from '../../data/store/history'
import { commits } from '../../data/store/repo'
import { computed } from 'vue'

export let use_commit_selection = () => {
	/** @type {string[]} */
	let default_selected_commits_hashes = []
	let selected_commits_hashes = state('repo:selected-commits-hashes', default_selected_commits_hashes).ref
	let selected_commits = computed({
		get() {
			return selected_commits_hashes.value
				?.map((hash) => commits.value.find((commit) => commit.hash === hash))
				.filter(is_truthy) || []
		},
		set(new_selection) {
			selected_commits_hashes.value = new_selection.map((commit) => commit.hash)
		},
	})
	let single_selected_commit = computed(() => {
		if (selected_commits.value.length === 1)
			return selected_commits.value[0]
	})

	function handle_user_commit_selection(/** @type {Commit} */ commit, /** @type {MouseEvent | undefined} */ event) {
		let selected_index = selected_commits.value.indexOf(commit)
		if (event?.ctrlKey || event?.metaKey)
			if (selected_index > -1)
				selected_commits.value = selected_commits.value.filter((_, i) => i !== selected_index)
			else
				selected_commits.value = [...selected_commits.value, commit]
		else if (event?.shiftKey) {
			let total_index = commits.value.indexOf(commit)
			let last_total_index = commits.value.indexOf(not_null(selected_commits.value.at(-1)))
			if (total_index > last_total_index && total_index - last_total_index < 1000)
				selected_commits.value = selected_commits.value.concat(commits.value.slice(last_total_index, total_index + 1).filter((c) =>
					! selected_commits.value.includes(c)))
		} else
			if (selected_index > -1)
				selected_commits.value = []
			else {
				selected_commits.value = [commit]
				push_history({ type: 'commit_hash', value: commit.hash })
			}
	}

	return { selected_commits, single_selected_commit, handle_user_commit_selection }
}
