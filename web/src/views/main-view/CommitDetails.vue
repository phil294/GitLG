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
				<div v-if="commit.stash && config_show_buttons" class="stash">
					<h3>
						Stash:
					</h3>
					<div class="row gap-5 wrap">
						<git-action-button v-for="action, i of stash_actions" :key="i" :git_action="action" />
					</div>
				</div>
				<div v-if="branch_tips.length" class="branch-tips">
					<ul v-if="config_show_buttons">
						<li v-for="branch_tip of branch_tips" :key="branch_tip.id">
							<ref-tip :commit="commit" :git_ref="branch_tip" />
							<div class="row gap-5 wrap">
								<git-action-button v-for="action, i of branch_actions(branch_tip)" :key="i" :git_action="action" />
								<button class="show-branch btn gap-5" title="Show the log for this branch only. Revert with a simple click on the main refresh button." @click="show_branch(branch_tip)">
									<i class="codicon codicon-eye" />Show
								</button>
							</div>
						</li>
					</ul>
					<commit-ref-tips v-else class="wrap gap-5" :commit="commit" />
				</div>
				<div v-if="tags.length" class="tags">
					<ul v-for="tag, tag_i of tags" :key="tag.id">
						<li>
							<ref-tip :commit="commit" :git_ref="tag" />
							<pre>{{ tag_details[tag_i] }}</pre>
							<div v-if="config_show_buttons" class="row gap-5 wrap">
								<git-action-button v-for="action, i of tag_actions(tag.name)" :key="i" :git_action="action" />
							</div>
						</li>
					</ul>
				</div>
				<div v-if="config_show_buttons" class="commit">
					<h3>
						Commit {{ commit.hash }}
						<button title="Jump to commit" @click="$emit('hash_clicked',commit.hash)">
							<i class="codicon codicon-link" />
						</button>
					</h3>
					<div class="row gap-5 wrap">
						<git-action-button v-for="action, i of commit_actions" :key="i" :git_action="action" />
					</div>
				</div>

				<template v-if="details_panel_position !== 'bottom'">
					<commit-diff :commit1="commit" />
				</template>

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
					Full hash: {{ commit.hash_long }}
					<button title="Jump to commit" @click="$emit('hash_clicked',commit.hash)">
						<i class="codicon codicon-link" />
					</button>
					<br>
					<template v-if="filtered_commits.length !== loaded_commits?.length">
						Index in filtered commits: {{ index_in_filtered_commits }}<br>
					</template>
					Index in all loaded commits: {{ index_in_loaded_commits }}<br>
					Index in raw graph output: {{ commit.index_in_graph_output }}
				</p>
			</div>
			<!-- TODO: fix this duplication with css -->
			<div :class="details_panel_position === 'bottom' ? 'flex-1' : ''" class="right">
				<template v-if="details_panel_position === 'bottom'">
					<commit-diff :commit1="commit" />
				</template>
			</div>
		</div>
	</div>
</template>

<script setup>
import { ref, computed, watchEffect } from 'vue'
import { git } from '../../bridge.js'
import { show_branch } from '../../data/store/index.js'
import { commit_actions as commit_actions_, stash_actions as stash_actions_, branch_actions as branch_actions_, tag_actions as tag_actions_ } from '../../data/store/actions.js'
import { filtered_commits, loaded_commits } from '../../data/store/repo.js'
import config from '../../data/store/config.js'

let props = defineProps({
	commit: {
		/** @type {Vue.PropType<Commit>} */
		type: Object,
		required: true,
	},
})
defineEmits(['hash_clicked'])

let details_panel_position = computed(() =>
	config.get_string('details-panel-position'))

let branch_tips = computed(() =>
	props.commit.refs.filter(is_branch))

let tags = computed(() => props.commit.refs.filter((ref_) =>
	ref_.type === 'tag'))
/** @type {Vue.Ref<string[]>} */
let tag_details = ref([])

let body = ref('')
/** @type {Vue.Ref<string[]>} */
let parent_hashes = ref([])
watchEffect(async () => {
	body.value = await git(`show -s --format="%b" ${props.commit.hash}`)

	tag_details.value = []
	for (let tag of tags.value) {
		let details = await git('show --format="" --quiet --color=never refs/tags/' + tag.name)
		tag_details.value.push(details)
	}

	parent_hashes.value = ((await git(`log --pretty=%p -n 1 ${props.commit.hash}`))).split(' ')
})

let commit_actions = computed(() =>
	commit_actions_(props.commit.hash).value)
let stash_actions = computed(() =>
	stash_actions_(props.commit.stash?.name || '').value)
let branch_actions = computed(() => (/** @type {Branch} */ branch) =>
	branch_actions_(branch).value)
let tag_actions = computed(() => (/** @type {string} */ tag_name) =>
	tag_actions_(tag_name).value)

let config_show_buttons = computed(() =>
	! config.get_boolean_or_undefined('hide-sidebar-buttons'))

let index_in_filtered_commits = computed(() =>
	props.commit ? filtered_commits.value.indexOf(props.commit) : -1)
let index_in_loaded_commits = computed(() =>
	props.commit ? loaded_commits.value?.indexOf(props.commit) || -1 : -1)

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
