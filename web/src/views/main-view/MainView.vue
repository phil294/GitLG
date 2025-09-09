<template>
	<div id="main-view" class="fill col">
		<ResizableSplit
			class="flex-1"
			:orientation="details_panel_position === 'bottom' ? 'horizontal' : 'vertical'"
			:show_second="selected_commits.length > 0"
			:initial_second="details_panel_position === 'bottom' ? 300 : 400"
			:min_first="300"
			:min_second="200"
		>
			<template #first>
				<div id="main-panel" class="col">
					<nav :inert="web_phase==='initializing_repo'" class="row align-center justify-space-between gap-10">
						<!-- TODO: . -->
						<details id="log-config" class="flex-1" :open="log_config_open" @toggle="log_config_open = /** @type {any} */($event.target).open">
							<summary class="align-center">
								Configure...
							</summary>
							<git-input ref="git_input_ref" :action="run_log" :git_action="log_action" hide_result />
						</details>
						<repo-selection />
						<aside class="center gap-20">
							<all-branches @branch_selected="jump_to_branch_tip_or_load" />
							<history @branch_selected="jump_to_branch_tip_or_load" @commit_clicked="jump_to_commit_hash_or_load" />
							<search-input id="search" @jump_to_commit="jump_to_commit_and_select" />
							<section id="actions" aria-roledescription="Global actions" class="center gap-5">
								<git-action-button v-for="action, i of global_actions" :key="i" :git_action="action" class="global-action" />
								<button id="refresh" class="btn center" :class="{'highlighted':highlight_refresh_button}" title="Refresh" :disabled="web_phase==='refreshing'||web_phase==='initializing'||web_phase==='initializing_repo'" @click="refresh()">
									<div class="icon-wrapper center">
										<i class="codicon codicon-refresh" />
									</div>
								</button>
							</section>
						</aside>
					</nav>
					<div id="quick-branch-tips">
						<div v-if="show_quick_branch_tips && !hidden_branch_tips_data.length" id="git-status">
							<p v-if="web_phase === 'initializing_repo'" class="loading">
								Loading...
							</p>
							<p v-else>
								Status: {{ git_status }}
							</p>
						</div>
						<template v-if="show_quick_branch_tips">
							<button v-for="tip_data of hidden_branch_tips_data" :key="tip_data.branch.id" title="Jump to branch tip" v-bind="tip_data.bind" @click="jump_to_branch_tip_or_load(tip_data.branch)">
								<ref-tip :git_ref="tip_data.branch" />
							</button>
						</template>
					</div>
					<div v-if="show_quick_branch_tips" id="branches-connection">
						<commit-row v-if="hidden_branch_tips_fake_commit" :commit="hidden_branch_tips_fake_commit" :height="110" class="vis" />
					</div>
					<p v-if="filtered_commits && !filtered_commits.length && web_phase !== 'initializing_repo'" id="no-commits-found">
						No commits found
					</p>
					<scroller id="log" ref="scroller_ref" />
				</div>
			</template>
			<template #second>
				<div id="details-panel" class="col flex-1">
					<template v-if="single_selected_commit">
						<commit-details id="selected-commit" :commit="single_selected_commit" class="flex-1 fill-w padding" @hash_clicked="jump_to_commit_hash_or_load($event)" />
						<button id="close-selected-commit" class="center" title="Close" @click="selected_commits=[]">
							<i class="codicon codicon-close" />
						</button>
					</template>
					<template v-else-if="selected_commits.length">
						<commits-details id="selected-commits" :commits="selected_commits" class="flex-1 fill-w padding" />
						<button id="close-selected-commits" class="center" title="Close" @click="selected_commits=[]">
							<i class="codicon codicon-close" />
						</button>
					</template>
				</div>
			</template>
		</ResizableSplit>
		<popup v-if="combine_branches_from_branch_name" @close="combine_branches_from_branch_name=''">
			<div class="drag-drop-branch-actions col center gap-5">
				<git-action-button v-for="action, i of combine_branches_actions" :key="i" :git_action="action" class="drag-drop-branch-action" />
			</div>
		</popup>
		<popup v-if="selected_git_action" @close="selected_git_action=null">
			<selected-git-action />
		</popup>
	</div>
</template>
<script setup>
import { computed, useTemplateRef, ref } from 'vue'
import ResizableSplit from '../../components/ResizableSplit.vue'
import config from '../../data/store/config'
import { _run_main_refresh, combine_branches_from_branch_name, main_view_highlight_refresh_button as highlight_refresh_button, main_view_git_input_ref, trigger_main_refresh as refresh, selected_git_action, web_phase } from '../../data/store'
import { combine_branches_actions, global_actions } from '../../data/store/actions'
import { filtered_commits, git_status, log_action, selected_commits, single_selected_commit } from '../../data/store/repo'
import { use_hidden_branch_tips } from './hidden-branch-tips'
import { use_scroller_jumpers } from './scroller-jumpers'

let details_panel_position = computed(() =>
	config.get_string('details-panel-position'))

let { jump_to_commit_and_select, jump_to_first_selected_commit, jump_to_branch_tip_or_load, jump_to_commit_hash_or_load } = use_scroller_jumpers()

let { fake_commit: hidden_branch_tips_fake_commit, branch_tip_data: hidden_branch_tips_data } = use_hidden_branch_tips()

let git_input_ref = useTemplateRef('git_input_ref')
// @ts-ignore TODO
main_view_git_input_ref.value = git_input_ref
let log_config_open = ref(false)
/**
 * Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
 * @param log_args {string} @param options {{fetch_stash_refs?: boolean, fetch_branches?: boolean}}
 */
async function run_log(/** @type {string} */ log_args, options) {
	let is_initializing_repo = web_phase.value === 'initializing_repo'
	try {
		await _run_main_refresh(log_args, options)
	} catch (error) {
		log_config_open.value = true
		web_phase.value = 'ready' // TODO: maybe new phase for this
		throw error
	}
	await sleep(0)
	if (is_initializing_repo)
		jump_to_first_selected_commit()
}

let show_quick_branch_tips = computed(() =>
	! config.get_boolean_or_undefined('hide-quick-branch-tips'))

</script>
<style scoped>
details#log-config {
	color: var(--text-secondary);
	overflow: hidden;
	min-width: 65px;
}
details#log-config[open] {
	padding: 10px;
	flex: 100% 1 0;
}
#main-panel {
	flex-shrink: 1;
	width: 100%;
	min-width: 30%;
	min-height: 30%;
	overflow: hidden auto;
	position: relative;
}
#main-panel > nav {
	padding: 5px;
	position: sticky;
	z-index: 2;
	border-bottom: 1px solid var(--vscode-sideBarSectionHeader-border);
}
#main-panel > nav #repo-selection {
	overflow: hidden;
	min-width: 50x;
	flex-shrink: 1;
}
#main-panel > nav > aside {
	flex-shrink: 3;
}
#main-panel > nav > aside > section#search {
	overflow: hidden;
}
#main-panel > nav > aside > section#actions {
	overflow: hidden;
	flex-shrink: 0;
}
#main-panel > nav > aside > section#actions :deep(button.btn) {
	padding: 1px 5px;
}
@keyframes spin {
	0% { transform: rotate(0deg); }
	100% { transform: rotate(360deg); }
}
#main-panel > nav > aside > section#actions > #refresh:disabled > .icon-wrapper {
	animation: spin 2s infinite linear;
}
#main-panel #quick-branch-tips,
#main-panel #branches-connection,
#main-panel #no-commits-found {
	padding-left: var(--container-padding);
}
#main-panel #branches-connection {
	height: 110px;
}
#main-panel #branches-connection :deep(>.commit>.vis>svg>path.vis-line) {
	stroke-dasharray: 4;
}
#main-panel #git-status {
	color: var(--text-secondary);
	height: 110px;
	position: fixed;
	overflow: auto;
	white-space: pre-line;
}
#main-panel #quick-branch-tips {
	position: sticky;
	z-index: 1;
}
#main-panel #quick-branch-tips > button {
	position: absolute;
}
#main-panel #quick-branch-tips > button:hover {
	z-index: 1;
}
#main-panel > nav > aside :deep(#show-all-branches[open] > .dv),
#main-panel > nav > aside :deep(#history[open] > .dv) {
	position: absolute;
	top: calc(100% + 5px);
	background: var(--vscode-editorWidget-background);
	border: 1px solid var(--vscode-editorWidget-border);
	border-radius: 5px;
	max-width: clamp(300px, 70vw, 80vw);
	max-height: min(70vh, 600px);
	overflow: auto;
	z-index: 5;
}
#main-panel > nav > aside :deep(#show-all-branches[open] > .dv) {
	right: 10px;
}
#main-panel > nav > aside :deep(#history[open] > .dv) {
	left: 50%;
	transform: translateX(-50%);
}
#main-panel #quick-branch-tips > #jump-to-top {
	right: -2px;
	top: 96px;
	color: #555;
}
#details-panel {
	min-width: 400px;
	min-height: 0;
	position: relative;
}
#details-panel #selected-commit,
#details-panel #selected-commits {
	overflow: auto;
	min-height: 0;
	z-index: 1;
	background: var(--vscode-editorWidget-background);
	border-left: 1px solid var(--vscode-sideBarSectionHeader-border);
}
#details-panel #close-selected-commit,
#details-panel #close-selected-commits {
	position: absolute;
	top: 10px;
	right: 10px;
	z-index: 1;
}
#details-panel .resize-hint {
	color: var(--text-secondary);
	font-size: small;
	padding-left: 10px;
	position: absolute;
	bottom: 0;
	left: 0;
	right: 0;
	z-index: 1;
	background: var(--vscode-editorWidget-background);
}
</style>
