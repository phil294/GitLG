<template lang="slm">
#main-view.fill.col
	.row.flex-1
		#left.col
			p v-if="!initialized"
				| Loading...
			p v-else-if="!filtered_commits.length"
				| No commits found
			nav.row.align-center.justify-space-between.gap-10
				details.config.flex-1
					summary Configure...
					git-input :git_action="log_action" hide_result="" :action="run_log" ref="git_input_ref"
				folder-selection
				aside.center.gap-20
					section#search.center.gap-5.justify-flex-end aria-roledescription="Search"
						#search-instructions v-if="txt_filter_type==='search'"
							| Jump between matches with ENTER / SHIFT+ENTER
						input.filter#txt-filter v-model="txt_filter" placeholder="🔍 search subject, hash, author" ref="txt_filter_ref" @keyup.enter="txt_filter_enter($event)"
						button#clear-filter v-if="txt_filter" @click="clear_filter()"
							| ✖
						label#filter-type-filter.row.align-center
							input type="radio" v-model="txt_filter_type" value="filter"
							| Filter
						label#filter-type-search.row.align-center
							input type="radio" v-model="txt_filter_type" value="search"
							| Search
					section#actions.center.gap-5 aria-roledescription="Global actions"
						git-action-button.global-action v-for="action of global_actions" :git_action="action"
						button#refresh.btn.center @click="refresh_main_view()" title="Refresh"
							i.codicon.codicon-refresh
			#quick-branch-tips
				all-branches @branch_selected="scroll_to_branch_tip($event)"
				#git-status v-if="!invisible_branch_tips_of_visible_branches_elems.length"
					| Status: {{ git_status }}
				button v-for="branch_elem of invisible_branch_tips_of_visible_branches_elems" @click="scroll_to_branch_tip(branch_elem.branch.id)" title="Jump to branch tip" v-bind="branch_elem.bind"
					ref-tip :git_ref="branch_elem.branch"
			#branches-connection
				visualization.vis v-if="connection_fake_commit" :commit="connection_fake_commit" :vis_max_length="vis_max_length"
			recycle-scroller#log.scroller.fill-w.flex-1 role="list" :items="filtered_commits" v-slot="{ item: commit }" key-field="i" size-field="scroll_height" :buffer="0" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref" tabindex="-1" v-context-menu="commit_context_menu_provider"
				.row.commit :class="{selected_commit:selected_commits.includes(commit),empty:!commit.hash}" @click="commit_clicked(commit,$event)" role="button" :data-commit-hash="commit.hash"
					visualization.vis :commit="commit" :vis_max_length="vis_max_length"
					.info.flex-1.row.gap-20 v-if="commit.hash"
						button
							.hash.flex-noshrink {{ commit.hash }}
						.subject-wrapper.flex-1.row.align-center
							div.vis.vis-v :style="commit.branch? {color:commit.branch.color} : undefined"
								| ● 
							.subject  {{ commit.subject }}
						.author.flex-noshrink :title="commit.author_email"
							| {{ commit.author_name }}
						.stats.flex-noshrink.row.align-center.justify-flex-end.gap-5
							.changes v-if="commit.stats" title="Changed lines in amount of files"
								span: strong {{ commit.stats.insertions + commit.stats.deletions }}
								span.grey  in 
								span.grey {{ commit.stats.files_changed }}
							progress.diff v-if="commit.stats" :value="(commit.stats.insertions / (commit.stats.insertions + commit.stats.deletions)) || 0" title="Ratio insertions / deletions"
						.datetime.flex-noshrink {{ commit.datetime }}
		#right.col.flex-1 v-if="selected_commit"
			commit-details#selected-commit.flex-1.fill-w.padding :commit="selected_commit" @hash_clicked="scroll_to_commit($event)"
			button#close-selected-commit.center @click="selected_commit=null" title="Close"
				i.codicon.codicon-close
			.resize-hint v-if="selected_commit"
				| ← resize
		#right.col.flex-1 v-else-if="selected_commits.length"
			commits-details#selected-commits.flex-1.fill-w.padding :commits="selected_commits"
			button#close-selected-commits.center @click="selected_commits=[]" title="Close"
				i.codicon.codicon-close
			.resize-hint v-if="selected_commit"
				| ← resize

	popup v-if="combine_branches_from_branch_name" @close="combine_branches_from_branch_name=''"
		.drag-drop-branch-actions.col.center.gap-5
			git-action-button.drag-drop-branch-action v-for="action of combine_branches_actions" :git_action="action"
	popup v-if="selected_git_action" @close="selected_git_action=null"
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
		#folder-selection
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
		:deep(>.vis>svg>line.vis-v)
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
		> #all-branches
			position absolute
			top 15px
			right 10px
			z-index 2
			max-width clamp(300px, 70vw, 80vw)
			background #161616dd
			box-shadow 0 0 5px 2px #161616dd
			padding 5px 10px 20px 20px
			border-radius 5px
	#log.scroller
		&:focus
			// Need tabindex so that pgUp/Down works consistently (idk why, probably vvs bug), but focus outline adds no value here
			outline none
		.commit
			--h 20px // must be synced with JS
			&.empty
				--h 6px // same
			height var(--h)
			line-height var(--h)
			cursor pointer
			user-select none
			&.selected_commit
				box-shadow 0 0 3px 0px gold
				background #292616


			// TODO: wait for vscode to be process.versions.chrome (dev tools) >= 112, then:
			// .vis:has(+.info:hover)
			// 	overflow hidden
			// Workaround until then (also see.vue-recycle-scroller__item-view.hover > .commit:
			.info:hover
				z-index 1
				background #161616
			&.selected_commit .info:hover
				background #292616


			.info
				border-top 1px solid #2e2e2e
				> *
					white-space pre
					overflow hidden
					text-overflow ellipsis
				.datetime, .hash
					font-family monospace
				> .subject-wrapper
					min-width 150px
					display inline-flex
					> *
						text-overflow ellipsis
					> .subject
						overflow hidden
						flex 1 1 30%
				> .datetime, > .author
					color grey
				> .datetime
					font-size 12px
				.stats
					width 93px

#right
	min-width 400px
	position relative
	#selected-commit, #selected-commits
		overflow auto
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
.vue-recycle-scroller__item-view.hover > .commit .info:hover
	background #323232 !important
</style>