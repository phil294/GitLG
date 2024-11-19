<template>
	<div class="commit-details">
		<div class="row fill-h">
			<div class="left flex-1">
				<h2 :title="commit.subject" class="summary">
					{{ commit.subject }}
				</h2>
				<p class="body">
					{{ body }}
				</p>
				<template v-if="config_show_buttons">
					<div v-if="stash" class="stash">
						<h3>
							Stash:
						</h3>
						<div class="row gap-5 wrap">
							<git-action-button v-for="action, i of stash_actions" :key="i" :git_action="action" />
						</div>
					</div>
					<div v-if="branch_tips.length" class="branch-tips">
						<ul>
							<li v-for="branch_tip of branch_tips" :key="branch_tip.id">
								<ref-tip :commit="commit" :git_ref="branch_tip" />
								<div class="row gap-5 wrap">
									<git-action-button v-for="action, i of branch_actions(branch_tip)" :key="i" :git_action="action" />
									<vscode-button class="show-branch" title="Show the log for this branch only. Revert with a simple click on the main refresh button." icon="eye" @click="show_branch(branch_tip)">
										Show
									</vscode-button>
								</div>
							</li>
						</ul>
					</div>
					<div v-if="tags.length" class="tags">
						<ul v-for="tag, tag_i of tags" :key="tag.id">
							<li>
								<ref-tip :commit="commit" :git_ref="tag" />
								<pre>{{ tag_details[tag_i] }}</pre>
								<div class="row gap-5 wrap">
									<git-action-button v-for="action, i of tag_actions(tag.name)" :key="i" :git_action="action" />
								</div>
							</li>
						</ul>
					</div>
					<div class="commit">
						<h3>
							This commit {{ commit.hash }}<button title="Jump to commit" @click="$emit('hash_clicked',commit.hash)">
								<i class="codicon codicon-link" />
							</button>:
						</h3>
						<div class="row gap-5 wrap">
							<git-action-button v-for="action, i of commit_actions" :key="i" :git_action="action" />
						</div>
					</div>
				</template>
				<template v-else>
					<div v-if="tags.length" class="tags">
						<ul v-for="tag, tag_i of tags" :key="tag.id">
							<li>
								<pre>{{ tag_details[tag_i] }}</pre>
							</li>
						</ul>
					</div>
				</template>

				<commit-file-changes v-if="details_panel_position !== 'bottom'" :files="changed_files" @show_diff="show_diff" @show_multi_diff="show_multi_diff" @view_rev="view_rev" />

				<h3>
					Parent commits
				</h3>
				<ul>
					<li v-for="parent_hash of parent_hashes" :key="parent_hash">
						{{ parent_hash }}
						<button title="Jump to commit" @click="$emit('hash_clicked',parent_hash)">
							<i class="codicon codicon-link" />
						</button>
					</li>
				</ul>
				<br>
				<details>
					<summary class="align-center">
						Compare...
					</summary>In order to compare this commit with another one, do <kbd>Ctrl/Cmd</kbd>+Click on any other commit in the main view
				</details>
				<h3>
					Details
				</h3>
				<p>
					Full hash: {{ commit.hash_long }}<br>
					<slot name="details_text" />
				</p>
			</div>
			<div :class="details_panel_position === 'bottom' ? 'flex-1' : ''" class="right">
				<commit-file-changes v-if="details_panel_position === 'bottom'" :files="changed_files" @show_diff="show_diff" @show_multi_diff="show_multi_diff" @view_rev="view_rev" />
			</div>
		</div>
	</div>
</template>

<script>
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
</script>

<script setup>
import { ref, computed, watchEffect } from 'vue'
import { git, exchange_message } from '../bridge.js'
import { commit_actions as commit_actions_, stash_actions as stash_actions_, branch_actions as branch_actions_, tag_actions as tag_actions_, config, show_branch } from '../state/store.js'

let props = defineProps({
	commit: {
		/** @type {Vue.PropType<Commit>} */
		type: Object,
		required: true,
	},
})
defineEmits(['hash_clicked'])

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

/** @type {Vue.Ref<import('./CommitFileChanges').FileDiff[]>} */
let changed_files = ref([])
let body = ref('')
/** @type {Vue.Ref<string[]>} */
let parent_hashes = ref([])
watchEffect(async () => {
	// so we can see untracked as well
	let get_files_command = stash.value
		? `-c core.quotepath=false stash show --include-untracked --numstat --summary --format="" ${props.commit.hash}`
		: `-c core.quotepath=false show --numstat --summary --format="" ${props.commit.hash}`
	changed_files.value = git_numstat_summary_to_changes_array(await git(get_files_command))

	body.value = await git(`show -s --format="%b" ${props.commit.hash}`)

	tag_details.value = []
	for (let tag of tags.value) {
		let details = await git('show --format="" --quiet --color=never refs/tags/' + tag.name)
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
function show_multi_diff() {
	return exchange_message('open-multi-diff', {
		hashes: [props.commit.hash + '~1', props.commit.hash],
		filenames: changed_files.value.map(f => f.path),
	})
}
function view_rev(/** @type {string} */ filepath) {
	return exchange_message('view-rev', {
		hash: props.commit.hash,
		filename: filepath,
	})
}
let commit_actions = computed(() =>
	commit_actions_(props.commit.hash).value)
let stash_actions = computed(() =>
	stash_actions_(stash.value?.name || '').value)
let branch_actions = computed(() => (/** @type {Branch} */ branch) =>
	branch_actions_(branch).value)
let tag_actions = computed(() => (/** @type {string} */ tag_name) =>
	tag_actions_(tag_name).value)

let config_show_buttons = computed(() =>
	! config.value['hide-sidebar-buttons'])

</script>
<style scoped>
h2.summary {
	white-space: pre-line;
	word-break: break-word;
	overflow: hidden;
	text-overflow: ellipsis;
	margin-top: 0;
}
.body {
	white-space: pre-wrap;
	word-break: break-word;
}
.branch-tips .ref-tip,
.tags .ref-tip {
	margin: 20px 10px 10px;
}
.left,
.right {
	overflow: auto;
}
</style>
