<template lang="slm">
#main-view.fill.col
	.row.flex-1
		#left.col
			p v-if="!filtered_commits.length"
				| No commits found
			nav.row.align-center.justify-space-between.gap-10
				details.log-config.flex-1
					summary Configure...
					git-input :git_action="log_action" hide_result="" :action="run_log" ref="git_input_ref"
				aside.center.gap-20
					section#search.center.gap-5.justify-flex-end aria-roledescription="Search"
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
						git-action-button.global-action v-for="action of global_actions" :git_action="action" @change="do_log()"
							button#refresh.btn.center @click="do_log()" title="Refresh"
								i.codicon.codicon-refresh
			all-branches @branch_selected="scroll_to_branch_tip($event)"
			#quick-branch-tips
				button v-for="branch_elem of invisible_branch_tips_of_visible_branches_elems" @click="scroll_to_branch_tip(branch_elem.branch.name)" title="Jump to branch tip" v-bind="branch_elem.bind"
					ref-tip :git_ref="branch_elem.branch"
			#branches-connection
				visualization.vis v-if="connection_fake_commit" :commit="connection_fake_commit" :vis_max_length="vis_max_length" :head_branch="head_branch"
			recycle-scroller#log.scroller.fill-w.flex-1 role="list" :items="filtered_commits" v-slot="{ item: commit }" key-field="i" size-field="scroll_height" :buffer="0" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref" tabindex="-1"
				.row.commit :class="{selected_commit:commit===selected_commit,empty:!commit.hash}" @click="selected_commit=selected_commit==commit?null:commit" role="button"
					visualization.vis :commit="commit" :vis_max_length="vis_max_length" :head_branch="head_branch"
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
			commit-details#selected-commit.flex-1.fill-w.padding :commit="selected_commit" @change="do_log()"
			button#close-selected-commit.center @click="selected_commit=null" title="Close"
				i.codicon.codicon-close
			#resize-hint v-if="selected_commit"
				| ← resize

	popup v-if="combine_branches_from_branch_name" @close="combine_branches_from_branch_name=''"
		.drag-drop-branch-actions.col.center.gap-5
			git-action-button.drag-drop-branch-action v-for="action of combine_branches_actions" :git_action="action" @change="do_log()"
</template>

<script lang="coffee" src="./MainView.coffee"></script>

<style lang="stylus" scoped>
details.log-config
	margin 0 0 0 10px
	color grey
	&[open]
		color unset
		padding 10px
#left
	flex-shrink 1
	width 100%
	min-width 30%
	resize horizontal
	overflow auto
	position relative
	> nav
		padding 5px 0
		margin 0 0 5px 0
		position sticky
		top 5px
		z-index 2
		border-bottom 1px solid #424242
		> aside
			> section#search
				input#txt-filter
					width 425px
				#clear-filter
					position relative
					right 20px
					width 0
					color grey
			> section#actions
				:deep(button.btn)
					font-size 21px
					padding 0 2px

	:deep(.is_head)
		border 3px solid white
		box-shadow 0px 0px 6px 4px #ffffff30, 0px 0px 4px 0px #ffffff30 inset
	#all-branches
		position absolute
		top 55px
		right 10px
		z-index 2
		max-width clamp(300px, 70vw, 80vw)
		background #202020dd
		box-shadow 0 0 5px 2px #202020dd
		padding 5px 10px 20px 20px
		border-radius 5px
	#quick-branch-tips, #branches-connection, #log.scroller
		padding-left var(--container-padding)
	#branches-connection
		height 100px
		:deep(>.vis>svg>line.vis-v)
			stroke-dasharray 4
	#quick-branch-tips
		position sticky
		z-index 1
		> button
			position absolute
			&:hover
				z-index 1
	#log.scroller
		&:focus
			// Need tabindex so that pgUp/Down works consistently (idk why, probably vvs bug), but focus outline adds no value here
			outline none
		.commit
			--h 23px // must be synced with JS
			&.empty
				--h 6px // same
			height var(--h)
			line-height var(--h)
			cursor pointer
			&.selected_commit
				box-shadow 0 0 3px 0px gold
			// TODO: wait for vscode to be process.versions.chrome (dev tools) >= 112, then:
			// .vis:has(+.info:hover)
			// 	overflow hidden
			// Workaround until then:
			.info:hover
				z-index 1
				background #202020
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
	#selected-commit
		overflow auto
	#close-selected-commit
		position absolute
		top 10px
		right 10px
	#resize-hint
		color #555555
		font-size small
		padding-left 10px

</style>

<style lang="stylus">
.vue-recycle-scroller__item-view.hover > .commit
	background #323232
</style>