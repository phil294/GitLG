import { ref, computed, defineComponent, watchEffect } from 'vue'
import { git, exchange_message } from '../bridge.js'
import { commit_actions, stash_actions, branch_actions, tag_actions, config, show_branch } from './store.js'

export const git_numstat_summary_to_changes_array = (/** @type {string} */ out) =>
	Object.values(out.split('\n').filter(Boolean)
		.reduce((/** @type {Record<string, { path: string, insertions: number, deletions: number, is_deletion?: boolean, is_creation?: boolean }>} */ all, line) => {
			if (line.startsWith(' ')) {
				let split = line.split(' ')
				let path = split.slice(4).join(' ')
				if (split[1] === 'delete')
					all[path].is_deletion = true
				else if (split[1] === 'create')
					all[path].is_creation = true
			} else {
				let split = line.split('\t')
				all[split[2]] = {
					path: split[2],
					insertions: Number(split[0]),
					deletions: Number(split[1]),
				}
			}
			return all
		}, {}))

export default defineComponent({
	props: {
		commit: {
			/** @type {Vue.PropType<Commit>} */
			type: Object,
			required: true,
		},
	},
	emits: ['hash_clicked'],
	setup(props) {
		let details_panel_position = computed(() =>
			config.value['details-panel-position'])

		let branch_tips = computed(() =>
			props.commit.refs.filter(is_branch))

		let tags = computed(() => props.commit.refs.filter((ref_) =>
			ref_.type === 'tag'))
		/** @type {Vue.Ref<string[]>} */
		let tag_details = ref([])

		let stash = computed(() => props.commit.refs.find((ref_) =>
			ref_.type === 'stash'))

		/** @type {Vue.Ref<import('./FilesDiffsList').FileDiff[]>} */
		let changed_files = ref([])
		let body = ref('')
		/** @type {Vue.Ref<string[]>} */
		let parent_hashes = ref([])
		watchEffect(async () => {
			// so we can see untracked as well
			let get_files_command = stash.value
				? `-c core.quotepath=false stash show --include-untracked --numstat --summary --format="" ${props.commit.hash}`
				: `-c core.quotepath=false diff --numstat --summary --format="" ${props.commit.hash}~1 ${props.commit.hash}`
			changed_files.value = git_numstat_summary_to_changes_array(await git(get_files_command))

			body.value = await git(`show -s --format="%b" ${props.commit.hash}`)

			tag_details.value = []
			for (let tag of tags.value) {
				let details = await git('show --format="" --quiet refs/tags/' + tag.name)
				tag_details.value.push(details)
			}

			parent_hashes.value = ((await git(`log --pretty=%p -n 1 ${props.commit.hash}`))).split(' ')
		})

		function show_diff(/** @type {string} */ filepath) {
			return exchange_message('open-diff', {
				hashes: [props.commit.hash + '~1', props.commit.hash],
				filename: filepath,
			})
		}
		function view_rev(/** @type {string} */ filepath) {
			return exchange_message('view-rev', {
				hash: props.commit.hash,
				filename: filepath,
			})
		}
		let _commit_actions = computed(() =>
			commit_actions(props.commit.hash).value)
		let _stash_actions = computed(() =>
			stash_actions(stash.value?.name || '').value)
		let _branch_actions = computed(() => (/** @type {Branch} */ branch) =>
			branch_actions(branch).value)
		let _tag_actions = computed(() => (/** @type {string} */ tag_name) =>
			tag_actions(tag_name).value)

		let config_show_buttons = computed(() =>
			! config.value['hide-sidebar-buttons'])
		return {
			branch_tips,
			tags,
			tag_details,
			stash,
			changed_files,
			show_diff,
			view_rev,
			body,
			commit_actions: _commit_actions,
			branch_actions: _branch_actions,
			tag_actions: _tag_actions,
			stash_actions: _stash_actions,
			show_branch,
			config_show_buttons,
			parent_hashes,
			details_panel_position,
		}
	},
})
