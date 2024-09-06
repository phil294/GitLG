<template>
	<div id="main-view" class="fill col">
		<div :class="details_panel_position === 'bottom' ? 'col' : 'row'" class="flex-1">
			<div id="main-panel" class="col">
				<p v-if="!initialized" class="loading">
					Loading...
				</p>
				<p v-else-if="!filtered_commits.length" class="no-commits-found">
					No commits found
				</p>
				<nav class="row align-center justify-space-between gap-10">
					<details id="log-config" class="flex-1">
						<summary class="align-center">
							Configure...
						</summary>
						<git-input ref="git_input_ref" :action="run_log" :git_action="log_action" hide_result="" />
					</details>
					<repo-selection />
					<aside class="center gap-20">
						<section id="search" aria-roledescription="Search" class="center gap-5 justify-flex-end">
							<input id="txt-filter" ref="txt_filter_ref" v-model="txt_filter" class="filter" placeholder="🔍 search subject, hash, author" @keyup.enter="txt_filter_enter($event)" @keyup.f3="txt_filter_enter($event)">
							<button v-if="txt_filter" id="regex-filter" :class="{active:txt_filter_regex}" class="center" @click="txt_filter_regex=!txt_filter_regex">
								<i class="codicon codicon-regex" title="Use Regular Expression (Alt+R)" />
							</button>
							<button v-if="txt_filter" id="clear-filter" class="center" title="Clear search" @click="clear_filter()">
								<i class="codicon codicon-close" />
							</button>
							<label id="filter-type-filter" class="row align-center">
								<input v-model="txt_filter_type" type="radio" value="filter">
								Filter
							</label>
							<label id="filter-type-jump" class="row align-center" title="Jump between matches with ENTER / SHIFT+ENTER or with F3 / SHIFT+F3">
								<input v-model="txt_filter_type" type="radio" value="jump">
								Jump
							</label>
						</section>
						<section id="actions" aria-roledescription="Global actions" class="center gap-5">
							<git-action-button v-for="action, i of global_actions" :key="i" :git_action="action" class="global-action" />
							<button id="refresh" class="btn center" title="Refresh" @click="refresh_main_view()">
								<i class="codicon codicon-refresh" />
							</button>
						</section>
					</aside>
				</nav>
				<div id="quick-branch-tips">
					<all-branches @branch_selected="scroll_to_branch_tip($event)" />
					<History @apply_txt_filter="$event=>txt_filter=$event" @branch_selected="scroll_to_branch_tip($event)" @commit_clicked="$event=>scroll_to_commit_hash_user($event.hash)" />
					<div v-if="config_show_quick_branch_tips && !invisible_branch_tips_of_visible_branches_elems.length" id="git-status">
						Status: {{ git_status }}
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
				<recycle-scroller id="log" ref="commits_scroller_ref" v-slot="{ item: commit }" v-context-menu="commit_context_menu_provider" :buffer="0" :emit-update="true" :item-size="scroll_item_height" :items="filtered_commits" class="scroller fill-w flex-1" key-field="i" role="list" tabindex="-1" @keydown="scroller_on_keydown" @update="commits_scroller_updated" @wheel="scroller_on_wheel">
					<commit-row :class="{selected_commit:selected_commits.includes(commit)}" :commit="commit" :data-commit-hash="commit.hash" role="button" @click="commit_clicked(commit,$event)" />
				</recycle-scroller>
			</div>
			<div v-if="selected_commit || selected_commits.length" id="details-panel" class="col flex-1">
				<template v-if="selected_commit">
					<commit-details id="selected-commit" :commit="selected_commit" class="flex-1 fill-w padding" @hash_clicked="scroll_to_commit_hash_user($event)" />
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
<script src="./MainView"></script>
<style scoped>
details#log-config {
	color: #808080;
	overflow: hidden;
	min-width: 65px;
}
details#log-config[open] {
	color: unset;
	padding: 10px;
	flex: 100% 1 0;
}
#main-panel {
	flex-shrink: 1;
	width: 100%;
	min-width: 30%;
	min-height: 30%;
	resize: both;
	overflow: auto;
	position: relative;
}
#main-panel > nav {
	padding: 5px;
	position: sticky;
	z-index: 2;
	background: #111;
	border-bottom: 1px solid #424242;
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
#main-panel > nav > aside > section#search #regex-filter,
#main-panel > nav > aside > section#search #clear-filter {
	position: relative;
	width: 0;
}
#main-panel > nav > aside > section#search #clear-filter,
#main-panel > nav > aside > section#search #regex-filter:not(.active) {
	color: #808080;
}
#main-panel > nav > aside > section#search #regex-filter {
	right: 32px;
}
#main-panel > nav > aside > section#search #clear-filter {
	right: 20px;
}
#main-panel > nav > aside > section#actions {
	overflow: hidden;
	flex-shrink: 0;
}
#main-panel > nav > aside > section#actions :deep(button.btn) {
	font-size: 21px;
	padding: 0 2px;
}
#main-panel #quick-branch-tips,
#main-panel #branches-connection,
#main-panel #log.scroller {
	padding-left: var(--container-padding);
}
#main-panel #branches-connection {
	height: 110px;
}
#main-panel #branches-connection :deep(>.commit>.vis>svg>path.vis-line) {
	stroke-dasharray: 4;
}
#main-panel #git-status {
	color: #555;
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
	background: rgba(22,22,22,0.867);
	box-shadow: 0 0 5px 2px rgba(22,22,22,0.867);
	border-radius: 5px;
}
#main-panel #quick-branch-tips > #all-branches {
	top: 15px;
	right: 10px;
	z-index: 3;
	max-width: clamp(300px, 70vw, 80vw);
}
#main-panel #quick-branch-tips > #history {
	top: 35px;
	right: 39px;
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
	cursor: pointer;
}
#main-panel #log.scroller .commit.selected_commit {
	box-shadow: 0 0 3px 0px #ffd700;
	background: #292616;
}
#main-panel #log.scroller .commit :deep(.info) {
	border-top: 1px solid #2e2e2e;
}
#main-panel #log.scroller .commit :deep(.info:hover) {
	z-index: 1;
	background: #161616;
}
:deep(#main-panel #log.scroller .commit.selected_commit .info:hover) {
	background: #292616;
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
	background: #161616;
}
#details-panel #close-selected-commit,
#details-panel #close-selected-commits {
	position: absolute;
	top: 10px;
	right: 10px;
	z-index: 1;
}
#details-panel .resize-hint {
	color: #555;
	font-size: small;
	padding-left: 10px;
}
</style>

<style>
.vue-recycle-scroller__item-view.hover > .commit {
	background: #323232;
}
</style>

<style>
.info:hover,
.info:hover,
.vue-recycle-scroller__item-view.hover > .commit .info:hover {
	background: #323232 !important;
}
</style>
