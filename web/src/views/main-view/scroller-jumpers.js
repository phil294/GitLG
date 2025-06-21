import { useTemplateRef, watch } from 'vue'
import { add_push_listener, git } from '../../bridge'
import { show_commit_hash } from '../../data/store'
import { push_history } from '../../data/store/history'
import { filtered_commits, selected_commits, visible_commits } from '../../data/store/repo'
import { is_regex as search_is_regex, search_str, type as search_type } from '../../data/store/search'

export let use_scroller_jumpers = () => {
	// TODO:
	// /** @type {Vue.ShallowRef<typeof import('./Scroller.vue')|null>} */
	/** @type {any} */
	let scroller_ref = useTemplateRef('scroller_ref')
	function jump_to_index_centered(/** @type {number} */ index) {
		// FIXME: this seems to fail if vertical space is taken up by commit details?
		scroller_ref.value?.scroll_to_item(index - Math.floor(visible_commits.value.length / 2))
	}
	function jump_to_top() {
		scroller_ref.value?.scroll_to_item(0)
	}

	async function jump_to_branch_tip_or_load(/** @type {Branch} */ branch) {
		search_str.value = ''
		let commit_i = filtered_commits.value.findIndex((commit) => {
			if (branch.inferred)
				return commit.vis_lines.some((vis_line) => vis_line.branch === branch)
			else
				return commit.refs.some((ref_) => ref_ === branch)
		})
		if (commit_i === -1) {
			let hash = await git(`rev-parse --short "${branch.id}"`)
			await show_commit_hash(hash)
			commit_i = 0
		}
		jump_to_index_centered(commit_i)
		let commit = not_null(filtered_commits.value[commit_i])
		// Not only jump to tip, but also select it, so the behavior is equal to clicking on
		// a branch name in a commit's ref list.
		selected_commits.value = [commit]
		// For now, set history always to commit_hash as this also shows the branches. Might revisit some day
		// if branch.inferred
		// 	push_history type: 'commit_hash', value: commit.hash
		// else
		// 	push_history type: 'branch_id', value: branch.id
		push_history({ type: 'commit_hash', value: commit.hash })
	}

	/** Like `jump_to_commit`, but if the hash isn't available, load it at all costs, and select */
	async function jump_to_commit_hash_or_load(/** @type {string} */ hash) {
		search_str.value = ''
		let commit_i = filtered_commits.value.findIndex((commit) =>
			commit.hash === hash)
		if (commit_i === -1)
			await show_commit_hash(hash)

		commit_i = filtered_commits.value.findIndex((commit) =>
			commit.hash === hash)
		if (commit_i === -1)
			throw new Error(`No commit found for hash '${hash}'`)

		jump_to_index_centered(commit_i)
		selected_commits.value = [not_null(filtered_commits.value[commit_i])]
		push_history({ type: 'commit_hash', value: hash })
	}
	function jump_to_commit(/** @type {Commit} */ commit) {
		let commit_i = filtered_commits.value.findIndex((c) => c === commit)
		jump_to_index_centered(commit_i)
	}
	function jump_to_commit_and_select(/** @type {Commit} */ commit) {
		jump_to_commit(commit)
		selected_commits.value = [commit]
	}
	function jump_to_first_selected_commit() {
		let first_selected_commit = selected_commits.value[0]
		if (first_selected_commit)
			jump_to_commit(first_selected_commit)
	}

	add_push_listener('show-selected-commit', async () => {
		let hash = selected_commits.value[0]?.hash
		if (! hash)
			return
		jump_to_commit_hash_or_load(hash)
	})

	watch([search_str, search_is_regex, search_type], () => {
		if (search_type.value === 'jump')
			return
		debounce(jump_to_first_selected_commit, 250)
	})

	return { jump_to_commit, jump_to_commit_and_select, jump_to_first_selected_commit, jump_to_top, jump_to_branch_tip_or_load, jump_to_commit_hash_or_load }
}
