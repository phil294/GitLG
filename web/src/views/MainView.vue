<template>
	<div id="main-view" class="fill col">
		<div :class="details_panel_position === 'bottom' ? 'col' : 'row'" class="flex-1">
			<div id="main-panel" class="col">
				<nav :inert="web_phase==='initializing_repo'" class="row align-center justify-space-between gap-10">
					<details id="log-config" class="flex-1">
						<summary class="align-center">
							Configure...
						</summary>
						<git-input ref="git_input_ref" :action="run_log" :git_action="log_action" hide_result />
					</details>
					<repo-selection />
					<aside class="center gap-20">
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
					<all-branches @branch_selected="jump_to_branch_tip_or_load($event)" />
					<history @branch_selected="jump_to_branch_tip_or_load($event)" @commit_clicked="$event=>jump_to_commit_hash_or_load($event)" />
					<div v-if="config_show_quick_branch_tips && !invisible_branch_tips_of_visible_branches_elems.length" id="git-status">
						<p v-if="web_phase === 'initializing_repo'" class="loading">
							Loading...
						</p>
						<p v-else>
							Status: {{ git_status }}
						</p>
					</div>
					<template v-if="config_show_quick_branch_tips">
						<button v-for="branch_elem of invisible_branch_tips_of_visible_branches_elems" :key="branch_elem.branch.id" title="Jump to branch tip" v-bind="branch_elem.bind" @click="jump_to_branch_tip_or_load(branch_elem.branch)">
							<ref-tip :git_ref="branch_elem.branch" />
						</button>
					</template>
					<button id="jump-to-top" title="Scroll to top" @click="jump_to_top()">
						<i class="codicon codicon-arrow-circle-up" />
					</button>
				</div>
				<div v-if="config_show_quick_branch_tips" id="branches-connection">
					<commit-row v-if="connection_fake_commit" :commit="connection_fake_commit" :height="110" class="vis" />
				</div>
				<p v-if="filtered_commits && !filtered_commits.length" id="no-commits-found">
					No commits found
				</p>
				<scroller id="log" ref="scroller_ref" />
			</div>
			<div v-if="selected_commits.length" id="details-panel" class="col flex-1">
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
		</div>
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
import { computed, useTemplateRef, watch } from 'vue'
// todo change this back again
import * as store from '../data/store'
import { combine_branches_actions, global_actions } from '../data/store/actions'
import { update_commit_stats } from '../data/store/commit-stats'
import { git_status, log_action, selected_commits, single_selected_commit, visible_commits, filtered_commits } from '../data/store/repo'
import { use_scroller_jumpers } from './main-view/scroller-jumpers'

let details_panel_position = computed(() =>
	store.config.value['details-panel-position'])

let { jump_to_commit_and_select, jump_to_first_selected_commit, jump_to_top, jump_to_branch_tip_or_load, jump_to_commit_hash_or_load } = use_scroller_jumpers()

let git_input_ref = useTemplateRef('git_input_ref')
// @ts-ignore TODO
store.main_view_git_input_ref.value = git_input_ref
/**
 * Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
 * @param log_args {string} @param options {{fetch_stash_refs?: boolean, fetch_branches?: boolean}}
 */
async function run_log(/** @type {string} */ log_args, options) {
	let is_initializing_repo = store.web_phase.value === 'initializing_repo'
	await store._run_main_refresh(log_args, options)
	await sleep(0)
	if (is_initializing_repo)
		jump_to_first_selected_commit()
}

// FIXME: store
watch(visible_commits, async () => {
	let visible_cp = visible_commits.value.filter((commit) =>
		commit.hash && ! commit.stats)
	if (! visible_cp.length)
		return
	if (! store.config.value['disable-commit-stats'])
		await update_commit_stats(visible_cp)
})
let visible_branches = computed(() => [
	...new Set(visible_commits.value.flatMap((commit) =>
		(commit.vis_lines || [])
			.map((v) => v.branch))),
].filter(is_truthy))
let visible_branch_tips = computed(() => [
	...new Set(visible_commits.value.flatMap((commit) =>
		commit.refs)),
].filter((ref_) =>
	ref_ && is_branch(ref_) && ! ref_.inferred))
let invisible_branch_tips_of_visible_branches = computed(() =>
// alternative: (visible_commits.value[0]?.refs.filter (ref) => ref.type == 'branch' and not ref.inferred and not visible_branch_tips.value.includes(ref)) or []
	visible_branches.value.filter((branch) =>
		(! branch.inferred || store.config.value['show-inferred-quick-branch-tips']) && ! visible_branch_tips.value.includes(branch)))

// To paint a nice gradient between branches at the top and the vis below:
let connection_fake_commit = computed(() => {
	let commit = visible_commits.value[0]
	if (! commit)
		return null
	return {
		refs: [], hash: '', hash_long: '', author_name: '', author_email: '', subject: '', index_in_graph_output: -1,
		vis_lines: commit.vis_lines
			.filter((line) => line.branch && invisible_branch_tips_of_visible_branches.value.includes(line.branch))
			.filter((line, i, all) => all.findIndex(l => l.branch === line.branch) === i) // rm duplicates
			.map((line) => {
				// This approx only works properly with curve radius 0
				let x = (line.x0 + line.xn) / 2
				return { ...line, xn: x, x0: x, xcs: x, xce: x, y0: 0, yn: 1 }
			}),
	}
})
// To show branch tips on top of connection_fake_commit lines
let invisible_branch_tips_of_visible_branches_elems = computed(() => {
	let row = -1
	return [...connection_fake_commit.value?.vis_lines || []].reverse()
		.map((line) => {
			if (! line.branch)
				return null
			row++
			if (row > 5)
				row = 0
			return {
				branch: line.branch,
				bind: {
					style: {
						left: 0 + store.vis_v_width.value * line.x0 + 'px',
						top: 0 + row * 19 + 'px',
					},
				},
			}
		}).filter(is_truthy) || []
})

let config_show_quick_branch_tips = computed(() =>
	! store.config.value['hide-quick-branch-tips'])

let { combine_branches_from_branch_name, trigger_main_refresh: refresh, main_view_highlight_refresh_button: highlight_refresh_button, web_phase, selected_git_action } = store

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
	resize: both;
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
#main-panel #quick-branch-tips > #all-branches,
#main-panel #quick-branch-tips > #history {
	position: absolute;
	background: var(--vscode-editorWidget-background);
	border: 1px solid var(--vscode-editorWidget-border);
	padding: 5px;
	padding-right: 10px;
	border-radius: 5px;
}
#main-panel #quick-branch-tips > #all-branches {
	top: 15px;
	right: 10px;
	z-index: 3;
	max-width: clamp(300px, 70vw, 80vw);
}
#main-panel #quick-branch-tips > #history {
	top: 52px;
	right: 40px;
	z-index: 2;
}
#main-panel #quick-branch-tips > #history[open] {
	left: 39px;
}
#main-panel #quick-branch-tips > #jump-to-top {
	right: -2px;
	top: 96px;
	color: #555;
}
#details-panel {
	min-width: 400px;
	min-height: min(300px, 40vh);
	position: relative;
}
#details-panel #selected-commit,
#details-panel #selected-commits {
	overflow: auto;
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
