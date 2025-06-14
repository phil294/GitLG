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
						<section id="search" aria-roledescription="Search" class="center gap-10 justify-flex-end">
							<div class="center">
								<input id="txt-filter" ref="txt_filter_ref" v-model="txt_filter" class="filter" placeholder="Search subject, hash, author" @keyup.enter="txt_filter_enter($event)" @keyup.f3="txt_filter_enter($event)">
								<button id="regex-filter" :class="{visible:txt_filter,active:txt_filter_regex}" class="center" @click="txt_filter_regex=!txt_filter_regex">
									<i class="codicon codicon-regex" title="Use Regular Expression (Alt+R)" />
								</button>
							</div>
							<label v-if="txt_filter" id="filter-type-filter" class="row align-center" title="If active, the list will be filtered. If inactive, you can jump between matches with ENTER / SHIFT+ENTER or with F3 / SHIFT+F3.">
								<input v-model="txt_filter_is_type_filter" type="checkbox">
								Filter
							</label>
						</section>
						<section id="actions" aria-roledescription="Global actions" class="center gap-5">
							<git-action-button v-for="action, i of global_actions" :key="i" :git_action="action" class="global-action" />
							<button id="refresh" class="btn center" :class="{'btn-highlighted':highlight_refresh_button}" title="Refresh" :disabled="web_phase==='refreshing'||web_phase==='initializing'||web_phase==='initializing_repo'" @click="refresh()">
								<div class="icon-wrapper center">
									<i class="codicon codicon-refresh" />
								</div>
							</button>
						</section>
					</aside>
				</nav>
				<div id="quick-branch-tips">
					<all-branches @branch_selected="scroll_to_branch_tip($event)" />
					<history @apply_txt_filter="$event=>txt_filter=$event" @branch_selected="scroll_to_branch_tip($event)" @commit_clicked="$event=>show_commit_hash($event)" />
					<div v-if="config_show_quick_branch_tips && !invisible_branch_tips_of_visible_branches_elems.length" id="git-status">
						<p v-if="web_phase === 'initializing_repo'" class="loading">
							Loading...
						</p>
						<p v-else>
							Status: {{ git_status }}
						</p>
					</div>
					<template v-if="config_show_quick_branch_tips">
						<button v-for="branch_elem of invisible_branch_tips_of_visible_branches_elems" :key="branch_elem.branch.id" title="Jump to branch tip" v-bind="branch_elem.bind" @click="scroll_to_branch_tip(branch_elem.branch)">
							<ref-tip :git_ref="branch_elem.branch" />
						</button>
					</template>
					<button id="jump-to-top" title="Scroll to top" @click="scroll_to_top()">
						<i class="codicon codicon-arrow-circle-up" />
					</button>
				</div>
				<div v-if="config_show_quick_branch_tips" id="branches-connection">
					<commit-row v-if="connection_fake_commit" :commit="connection_fake_commit" :height="110" class="vis" />
				</div>
				<p v-if="commits && !commits.length" id="no-commits-found">
					No commits found
				</p>
				<recycle-scroller id="log" ref="commits_scroller_ref" v-slot="{ item: commit }" v-context-menu="commit_context_menu_provider" :buffer="0" :emit-update="true" :item-size="scroll_item_height" :items="filtered_commits" class="scroller fill-w flex-1" key-field="index_in_graph_output" role="list" tabindex="-1" @keydown="scroller_on_keydown" @update="commits_scroller_updated" @wheel="scroller_on_wheel">
					<commit-row :class="{selected_commit:selected_commits.includes(commit)}" :commit="commit" :data-commit-hash="commit.hash" @click="commit_clicked(commit,$event)" />
				</recycle-scroller>
			</div>
			<div v-if="selected_commit || selected_commits.length" id="details-panel" class="col flex-1">
				<template v-if="selected_commit">
					<commit-details id="selected-commit" :commit="selected_commit" class="flex-1 fill-w padding" @hash_clicked="show_commit_hash($event)">
						<template #details_text>
							<template v-if="filtered_commits.length !== commits?.length">
								Index in filtered commits: {{ selected_commit_index_in_filtered_commits }}<br>
							</template>
							Index in all loaded commits: {{ selected_commit_index_in_commits }}<br>
							Index in raw graph output: {{ selected_commit.index_in_graph_output }}
						</template>
					</commit-details>
					<button id="close-selected-commit" class="center" title="Close" @click="selected_commits=[]">
						<i class="codicon codicon-close" />
					</button>
					<div v-if="selected_commit" class="resize-hint">
						← resize
					</div>
				</template>
				<template v-else-if="selected_commits.length">
					<commits-details id="selected-commits" :commits="selected_commits" class="flex-1 fill-w padding" />
					<button id="close-selected-commits" class="center" title="Close" @click="selected_commits=[]">
						<i class="codicon codicon-close" />
					</button>
					<div v-if="selected_commit" class="resize-hint">
						← resize
					</div>
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
import { ref, computed, watch, onMounted, useTemplateRef } from 'vue'
import * as store from '../state/store.js'
import { add_push_listener, exchange_message, git } from '../bridge.js'
import vContextMenu from '../directives/context-menu'

let details_panel_position = computed(() =>
	store.config.value['details-panel-position'])

/** @type {string[]} */
let default_selected_commits_hashes = []
let selected_commits_hashes = store.state('repo:selected-commits-hashes', default_selected_commits_hashes).ref
let selected_commits = computed({
	get() {
		return selected_commits_hashes.value
			?.map((hash) => filtered_commits.value.find((commit) => commit.hash === hash))
			.filter(is_truthy) || []
	},
	set(commits) {
		selected_commits_hashes.value = commits.map((commit) => commit.hash)
	},
})
let selected_commit = computed(() => {
	if (selected_commits.value.length === 1)
		return selected_commits.value[0]
})
let selected_commit_index_in_filtered_commits = computed(() =>
	selected_commit.value ? filtered_commits.value.indexOf(selected_commit.value) : -1)
let selected_commit_index_in_commits = computed(() =>
	selected_commit.value ? store.commits.value?.indexOf(selected_commit.value) || -1 : -1)
function commit_clicked(/** @type {Commit} */ commit, /** @type {MouseEvent | undefined} */ event) {
	if (! commit.hash)
		return
	let selected_index = selected_commits.value.indexOf(commit)
	if (event?.ctrlKey || event?.metaKey)
		if (selected_index > -1)
			selected_commits.value = selected_commits.value.filter((_, i) => i !== selected_index)
		else
			selected_commits.value = [...selected_commits.value, commit]
	else if (event?.shiftKey) {
		let total_index = filtered_commits.value.indexOf(commit)
		let last_total_index = filtered_commits.value.indexOf(not_null(selected_commits.value.at(-1)))
		if (total_index > last_total_index && total_index - last_total_index < 1000)
			selected_commits.value = selected_commits.value.concat(filtered_commits.value.slice(last_total_index, total_index + 1).filter((c) =>
				! selected_commits.value.includes(c)))
	} else
		if (selected_index > -1)
			selected_commits.value = []
		else {
			selected_commits.value = [commit]
			store.push_history({ type: 'commit_hash', value: commit.hash })
		}
}

// TODO: externalize
let txt_filter = ref('')
let txt_filter_is_type_filter = store.state('filter-options-is-filter', false).ref
let txt_filter_regex = store.state('filter-options-regex', false).ref
let txt_filter_ref = /** @type {Readonly<Vue.ShallowRef<HTMLInputElement|null>>} */ (useTemplateRef('txt_filter_ref'))
function txt_filter_filter(/** @type {Commit} */ commit) {
	let search_for = txt_filter.value.toLowerCase()
	/** @type {RegExp | undefined} */
	let search_for_regex = undefined
	if (txt_filter_regex.value)
		try {
			search_for_regex = new RegExp(search_for)
		} catch (_) {
			return false
		}

	for (let str of [commit.subject, commit.hash_long, commit.author_name, commit.author_email, ...commit.refs.map((r) => r.id)].map((s) => s.toLowerCase()))
		if (txt_filter_regex.value) {
			if (str?.match(search_for_regex || '?'))
				return true
		} else if (str?.includes(search_for))
			return true
}
let filtered_commits = computed(() => {
	if (! txt_filter.value || ! txt_filter_is_type_filter.value)
		return store.commits.value || []
	return (store.commits.value || []).filter(txt_filter_filter)
})
let txt_filter_last_i = -1
document.addEventListener('keyup', (e) => {
	if (e.key === 'F3' || e.ctrlKey && e.key === 'f')
		txt_filter_ref.value?.focus()
	if (txt_filter.value && e.key === 'r' && e.altKey)
		txt_filter_regex.value = ! txt_filter_regex.value
})
function txt_filter_enter(/** @type {KeyboardEvent} */ event) {
	if (txt_filter_is_type_filter.value)
		return
	let next_match_index = 0
	if (event.shiftKey) {
		let next = [...filtered_commits.value.slice(0, txt_filter_last_i)].reverse().findIndex(txt_filter_filter)
		if (next > -1)
			next_match_index = txt_filter_last_i - 1 - next
		else
			next_match_index = filtered_commits.value.length - 1
	} else {
		let next = filtered_commits.value.slice(txt_filter_last_i + 1).findIndex(txt_filter_filter)
		if (next > -1)
			next_match_index = txt_filter_last_i + 1 + next
		else
			next_match_index = 0
	}
	scroll_to_index_centered(next_match_index)
	txt_filter_last_i = next_match_index
	debounce(() => {
		let commit = filtered_commits.value[txt_filter_last_i]
		if (commit)
			selected_commits.value = [commit]
	}, 100)
}
watch(txt_filter, () => {
	if (txt_filter.value)
		store.push_history({ type: 'txt_filter', value: txt_filter.value })
	if (! txt_filter_is_type_filter.value)
		return
	debounce(() => {
		if (selected_commit.value)
			scroll_to_commit(selected_commit.value)
	}, 250)
})

async function scroll_to_branch_tip(/** @type {Branch} */ branch) {
	txt_filter.value = ''
	let commit_i = filtered_commits.value.findIndex((commit) => {
		if (branch.inferred)
			return commit.vis_lines.some((vis_line) => vis_line.branch === branch)
		else
			return commit.refs.some((ref_) => ref_ === branch)
	})
	if (commit_i === -1) {
		let hash = await git(`rev-parse --short "${branch.id}"`)
		await store.load_commit_hash(hash)
		commit_i = 0
	}
	scroll_to_index_centered(commit_i)
	let commit = not_null(filtered_commits.value[commit_i])
	// Not only scroll to tip, but also select it, so the behavior is equal to clicking on
	// a branch name in a commit's ref list.
	selected_commits.value = [commit]
	// For now, set history always to commit_hash as this also shows the branches. Might revisit some day
	// if branch.inferred
	// 	store.push_history type: 'commit_hash', value: commit.hash
	// else
	// 	store.push_history type: 'branch_id', value: branch.id
	store.push_history({ type: 'commit_hash', value: commit.hash })
}
function scroll_to_commit_hash(/** @type {string} */ hash) {
	let commit_i = filtered_commits.value.findIndex((commit) =>
		commit.hash === hash)
	if (commit_i === -1) {
		console.warn(new Error().stack)
		console.warn(`No commit found for hash ${hash}`)
	}
	scroll_to_index_centered(commit_i)
	// selected_commits.value = [not_null(filtered_commits.value[commit_i])]
}
/** Like `scroll_to_commit_hash`, but if the hash isn't available, load it at all costs, and select */
async function show_commit_hash(/** @type {string} */ hash) {
	txt_filter.value = ''
	let commit_i = filtered_commits.value.findIndex((commit) =>
		commit.hash === hash)
	if (commit_i === -1)
		await store.load_commit_hash(hash)

	commit_i = filtered_commits.value.findIndex((commit) =>
		commit.hash === hash)
	if (commit_i === -1)
		throw new Error(`No commit found for hash '${hash}'`)

	scroll_to_index_centered(commit_i)
	selected_commits_hashes.value = [hash]
	store.push_history({ type: 'commit_hash', value: hash })
}
function scroll_to_commit(/** @type {Commit} */ commit) {
	let commit_i = filtered_commits.value.findIndex((c) => c === commit)
	scroll_to_index_centered(commit_i)
}
function scroll_to_top() {
	commits_scroller_ref.value?.scrollToItem(0)
}
add_push_listener('show-selected-commit', async () => {
	let hash = selected_commits_hashes.value[0]
	if (! hash)
		return
	show_commit_hash(hash)
})

let git_input_ref = useTemplateRef('git_input_ref')
// @ts-ignore TODO
store.main_view_git_input_ref.value = git_input_ref
/* Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git.
    	This function exists so we can modify the args before sending to git, otherwise
    	GitInput would have done the git call  */
async function run_log(/** @type {string} */ log_args) {
	let is_initializing_repo = store.web_phase.value === 'initializing_repo'
	await store.main_view_action(log_args)
	await sleep(0)
	if (is_initializing_repo) {
		let first_selected_hash = selected_commits.value[0]?.hash
		if (first_selected_hash)
			scroll_to_commit_hash(first_selected_hash)
	}
}

// @ts-ignore TODO: idk
let commits_scroller_ref = /** @type {Readonly<Vue.ShallowRef<InstanceType<typeof import('vue-virtual-scroller').RecycleScroller>|null>>} */ (useTemplateRef('commits_scroller_ref'))
/** @type {Vue.Ref<Commit[]>} */
let visible_commits = ref([])
let scroller_start_index = 0
function commits_scroller_updated(/** @type {number} */ start_index, /** @type {number} */ end_index) {
	scroller_start_index = start_index
	let commits_start_index = scroller_start_index < 3 ? 0 : scroller_start_index
	debounce(() =>
		visible_commits.value = filtered_commits.value.slice(commits_start_index, end_index), 50)
}
function scroller_on_wheel(/** @type {WheelEvent} */ event) {
	if (store.config.value['disable-scroll-snapping'])
		return
	event.preventDefault()
	commits_scroller_ref.value?.scrollToItem(scroller_start_index + Math.round(event.deltaY / 20))
}
function scroller_on_keydown(/** @type {KeyboardEvent} */ event) {
	if (store.config.value['disable-scroll-snapping'])
		return
	if (event.key === 'ArrowDown') {
		event.preventDefault()
		commits_scroller_ref.value?.scrollToItem(scroller_start_index + 2)
	} else if (event.key === 'ArrowUp') {
		event.preventDefault()
		commits_scroller_ref.value?.scrollToItem(scroller_start_index - 2)
	}
}
function scroll_to_index_centered(/** @type {number} */ index) {
	commits_scroller_ref.value?.scrollToItem(index - Math.floor(visible_commits.value.length / 2))
}
let scroll_item_height = computed(() =>
	store.config.value['row-height'])

watch(visible_commits, async () => {
	let visible_cp = visible_commits.value.filter((commit) =>
		commit.hash && ! commit.stats)
	if (! visible_cp.length)
		return
	if (! store.config.value['disable-commit-stats'])
		await store.update_commit_stats(visible_cp)
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

let global_actions = computed(() =>
	store.global_actions.value)

onMounted(() => {
	// didn't work with @keyup.escape.native on the components root element
	// when focus was in a sub component (??) so doing this instead:
	document.addEventListener('keyup', (e) => {
		if (e.key === 'Escape')
			selected_commits.value = []
	})
	commits_scroller_ref.value.$el.focus()
})

// It didn't work with normal context binding to the scroller's commit elements, either a bug
// of context-menu update or I misunderstood something about vue-virtual-scroller, but this
// works around it reliably (albeit uglily)
let commit_context_menu_provider = computed(() => (/** @type {MouseEvent} */ event) => {
	if (! (event.target instanceof HTMLElement) && ! (event.target instanceof SVGElement))
		return
	let el = event.target
	while (el.parentElement && ! el.parentElement.classList.contains('commit'))
		el = el.parentElement
	if (! el.parentElement)
		return
	let hash = el.parentElement.dataset.commitHash
	if (! hash)
		throw 'commit context menu element has no hash?'
	return store.commit_actions(hash).value.map((action) => ({
		label: action.title,
		icon: action.icon,
		action() {
			store.selected_git_action.value = action
		},
	})).concat({
		label: 'Copy hash',
		icon: 'clippy',
		action() {
			exchange_message('clipboard-write-text', hash)
		},
	})
})

let config_show_quick_branch_tips = computed(() =>
	! store.config.value['hide-quick-branch-tips'])

let { combine_branches_from_branch_name, combine_branches_actions, refresh_main_view: refresh, main_view_highlight_refresh_button: highlight_refresh_button, web_phase, selected_git_action, git_status, commits, log_action } = store

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
#main-panel > nav > aside > section#search input#txt-filter {
	width: 425px;
	overflow: hidden;
}
#main-panel > nav > aside > section#search #regex-filter {
	min-width: 20px;
	margin-left: -23px;
	opacity: 0;
	visibility: hidden;
	transition: all 0.2s ease-in;
	transition-property: opacity, visibility;
	&.visible {
		opacity: 1;
		visibility: visible;
	}
	&.active {
		color: var(--vscode-inputOption-activeForeground);
		border: 1px solid var(--vscode-inputOption-activeBorder);
		background-color: var(--vscode-inputOption-activeBackground);
		border-radius: 3px;
	}
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
#main-panel #log.scroller:focus {
	outline: none;
}
#main-panel #log.scroller .commit {
	padding-left: var(--container-padding);
	cursor: pointer;
}
#main-panel #log.scroller .commit.selected_commit {
	background: var(--vscode-list-activeSelectionBackground)
}
#main-panel #log.scroller .commit :deep(.info) {
	border-top: 1px solid var(--vscode-sideBarSectionHeader-border);
	padding-right: var(--container-padding);
}
#main-panel #log.scroller .commit :deep(.info:hover) {
	z-index: 1;
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

<style>
.vue-recycle-scroller__item-view.hover > .commit {
	background: var(--vscode-list-hoverBackground);
}
</style>
