<template lang="slm">
#main-view.fill.col
	.row.flex-1
		#left.col
			/ todo use suspend
			p.loading v-if="!initialized"
				| Loading...
			p.no-commits-found v-else-if="!filtered_commits.length"
				| No commits found
			nav.row.align-center.justify-space-between.gap-10
				details.config.flex-1
					summary.align-center Configure...
					git-input :git_action="log_action" hide_result="" :action="run_log" ref="git_input_ref"
				repo-selection
				aside.center.gap-20
					section#search.center.gap-5.justify-flex-end aria-roledescription="Search"
						#search-instructions v-if="txt_filter_type==='jump' || txt_filter_type==='jumphash'"
							| Jump between matches with ENTER / SHIFT+ENTER
						input.filter#txt-filter v-model="txt_filter" placeholder="🔍 search subject, hash, author" ref="txt_filter_ref" @keyup.enter="txt_filter_enter($event)"
						button#clear-filter v-if="txt_filter" @click="clear_filter()"
							| ✖
						label#filter-type-filter.row.align-center
							input type="radio" v-model="txt_filter_type" value="jumphash"
							| Jump (Hash)
						label#filter-type-filter.row.align-center
							input type="radio" v-model="txt_filter_type" value="filter"
							| Filter
						label#filter-type-jump.row.align-center
							input type="radio" v-model="txt_filter_type" value="jump"
							| Jump
					section#actions.center.gap-5 aria-roledescription="Global actions"
						git-action-button.global-action v-for="action of global_actions" :git_action="action"
						button#refresh.btn.center @click="go_to_head()" title="Go To HEAD"
							i.codicon.codicon-git-merge
						button#refresh.btn.center :disabled="!selected_commit" @click="temporary_view_commit_only()" title="Current Commit Only"
							i.codicon.codicon-telescope
						button#refresh.btn.center @click="reset_command()" title="Reset Git Log Command"
							i.codicon.codicon-redo
						button#refresh.btn.center @click="refresh_main_view()" title="Refresh"
							i.codicon.codicon-refresh
			#quick-branch-tips
				all-branches @branch_selected="scroll_to_branch_tip($event)" ref="all_branches_ref"
				history @branch_selected="scroll_to_branch_tip($event)" @commit_clicked="$event=>scroll_to_commit_user($event.full_hash)" @apply_txt_filter="$event=>txt_filter=$event"
				#git-status v-if="config_show_quick_branch_tips && !invisible_branch_tips_of_visible_branches_elems.length"
					| Status: {{ git_status }}
				button v-if="config_show_quick_branch_tips" v-for="branch_elem of invisible_branch_tips_of_visible_branches_elems" @click="scroll_to_branch_tip(branch_elem.branch)" title="Jump to branch tip" v-bind="branch_elem.bind"
					ref-tip :git_ref="branch_elem.branch"
				button#jump-to-top @click="scroll_to_top()" title="Scroll to top"
					i.codicon.codicon-arrow-circle-up
			#branches-connection v-if="config_show_quick_branch_tips"
				commit-row.vis :height="110" v-if="connection_fake_commit" :commit="connection_fake_commit"
			recycle-scroller#log.scroller.fill-w.flex-1 role="list" :items="filtered_commits" v-slot="{ item: commit }" key-field="i" :item-size="scroll_item_height" :buffer="0" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref" tabindex="-1" v-context-menu="commit_context_menu_provider" @wheel="scroller_on_wheel" @keydown="scroller_on_keydown"
				commit-row :commit="commit" :class="{selected_commit:selected_commits.includes(commit)}" @click="commit_clicked(commit,$event)" @commit_sticky_selected="event => commit_sticky_selected(commit, event)" :should_show_sticky_select="true" :selected_commits_from_sticky_map="selected_commits_from_sticky_map" :sticky_selected_commits_map="sticky_selected_commits_map" :sticky_selected_commits_reverted="sticky_selected_commits_reverted" role="button" :data-commit-hash="commit.full_hash"
		#right.col.flex-1 v-if="selected_commit || selected_commits.length"
			template v-if="selected_commit"
				commit-details#selected-commit.flex-1.fill-w.padding :commit="selected_commit" @hash_clicked="scroll_to_commit_user($event)"
				button#close-selected-commit.center @click="selected_commits=[]" title="Close"
					i.codicon.codicon-close
				.resize-hint v-if="selected_commit"
					| ← resize
			template v-else-if="selected_commits.length"
				commits-details#selected-commits.flex-1.fill-w.padding :commits="selected_commits" @hash_clicked="scroll_to_commit($event)"
				button#close-selected-commits.center @click="selected_commits=[]" title="Close"
					i.codicon.codicon-close
				.resize-hint v-if="selected_commit"
					| ← resize

	popup v-if="combine_branches_from_branch_name" @close="combine_branches_from_branch_name=''"
		.drag-drop-branch-actions.col.center.gap-5
			git-action-button.drag-drop-branch-action v-for="action of combine_branches_actions" :git_action="action"
	popup v-if="selected_git_action && !selected_git_action.args.startsWith('special:')" @close="selected_git_action=null"
		selected-git-action
</template>

<script lang="coffee" src="./MainView.coffee"></script>

<style lang="stylus" scoped>
details.config
	color grey
	&[open]
		color unset
		padding 10px
		flex 100% 1 0
#left
	flex-shrink 1
	width 100%
	min-width 30%
	resize horizontal
	overflow auto
	position relative
	> nav
		padding 5px
		position sticky
		z-index 2
		background #111111
		border-bottom 1px solid #424242
		#repo-selection
			overflow hidden
		> aside
			> section#search
				overflow hidden
				input#txt-filter
					width 425px
				#clear-filter
					position relative
					right 20px
					width 0
					color grey
			> section#actions
				overflow hidden
				:deep(button.btn)
					font-size 21px
					padding 0 2px

	#quick-branch-tips, #branches-connection, #log.scroller
		padding-left var(--container-padding)
	#branches-connection
		height 110px
		:deep(>.commit>.vis>svg>path.vis-line)
			stroke-dasharray 4
	#git-status
		color #555
		height 110px
		position fixed
		overflow auto
		white-space pre-line
	#quick-branch-tips
		position sticky
		z-index 1
		> button
			position absolute
			&:hover
				z-index 1
		> #all-branches, > #history
			position absolute
			background #161616dd
			box-shadow 0 0 5px 2px #161616dd
			border-radius 5px
		> #all-branches
			top 15px
			right 10px
			z-index 3
			max-width clamp(300px, 70vw, 80vw)
		> #history
			top 35px
			right 39px
			z-index 2
			&[open]
				left 39px
		> #jump-to-top
			right -2px
			top 96px
			color #555555
	#log.scroller
		&:focus
			// Need tabindex so that pgUp/Down works consistently (idk why, probably vvs bug), but focus outline adds no value here
			outline none
		.commit
			cursor pointer
			&.selected_commit
				box-shadow 0 0 3px 0px gold
				background #292616
			:deep(.info)
				border-top 1px solid #2e2e2e


			// TODO: wait for vscode to be process.versions.chrome (dev tools) >= 112, then:
			// .vis:has(+.info:hover)
			// 	overflow hidden
			// Workaround until then (also see.vue-recycle-scroller__item-view.hover > .commit:
			:deep(.info:hover)
				z-index 1
				background #161616
			:deep(&.selected_commit .info:hover)
				background #292616


#right
	min-width 400px
	position relative
	#selected-commit, #selected-commits
		overflow auto
		z-index 1
		background #161616
	#close-selected-commit, #close-selected-commits
		position absolute
		top 10px
		right 10px
	.resize-hint
		color #555555
		font-size small
		padding-left 10px

</style>

<style lang="stylus">
.vue-recycle-scroller__item-view.hover > .commit
	background #323232

	// TODO: see above
	.info:hover
		background #323232 !important
</style>