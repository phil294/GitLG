1<template lang="slm">
#main-view.fill.col
	details
		summary Configure...
		git-input :git_action="log_action" hide_result="" :action="run_log" ref="git_input_ref"
	.row.flex-1
		#left.col.flex-noshrink
			p v-if="!commits.length"
				| No commits found
			nav.row.align-center.justify-space-between.gap-10
				ul#branches.row.align-center.wrap.flex-1.gap-3
					li.ref.branch.visible.active v-for="branch of visible_branches" :class="{is_head:branch.name===head_branch, is_hovered:branch.name===hovered_branch_name}"
						button :style="{color:branch.color}" @click="scroll_to_branch_tip(branch)" title="Jump to branch tip" v-drag="branch.name" v-drop="branch_drop(branch.name)"
							| {{ branch.name }}
					li.show-invisible_branches v-if="invisible_branches.length"
						button @click="show_invisible_branches = ! show_invisible_branches"
							| Show all >>
					template v-if="show_invisible_branches"
						li.ref.branch.invisible v-for="branch of invisible_branches" :class="{is_head:branch.name===head_branch}"
							button :style="{color:branch.color}" @click="scroll_to_branch_tip(branch)" title="Jump to branch tip" v-drag="branch.name" v-drop="branch_drop(branch.name)"
								| {{ branch.name }}
						li Click on any of the branch names to jump to the tip of it.
				aside#actions.center.gap-5
					git-action-button.global-action v-for="action of global_actions" :git_action="action" @change="do_log()"
					button#refresh.btn @click="do_log()" title="Refresh" ⟳
			aside#search.center.gap-5.justify-flex-end
				input#txt-filter v-model="txt_filter" placeholder="🔍 search subject, hash, author" ref="txt_filter_ref" @keyup.enter="txt_filter_enter($event)"
				button#clear-filter v-if="txt_filter" @click="clear_filter()"
					| ✖
				label#filter-type-filter.row.align-center
					input type="radio" v-model="txt_filter_type" value="filter"
					| Filter
				label#filter-type-search.row.align-center
					input type="radio" v-model="txt_filter_type" value="search"
					| Search
			recycle-scroller#log.scroller.fill-w.flex-1 role="list" :items="commits" v-slot="{ item: commit }" key-field="i" size-field="scroll_height" :buffer="0" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref" tabindex="-1"
				.row.commit :class="{active:commit===selected_commit,empty:!commit.hash}"
					.vis :style="vis_style"
						span.vis-v v-for="v of commit.vis" :style="v.branch? {color:v.branch.color} : undefined" :class="{is_head:v.branch&&v.branch.name===head_branch}" :data-branch-name="v.branch? v.branch.name : undefined"
							| {{ v.char }}
					.info.flex-1.row.gap-20 v-if="commit.hash" @click="commit_clicked(commit)"
						button
							.hash.flex-noshrink {{ commit.hash }}
						.subject-wrapper.flex-1.row.align-center
							div.vis.vis-v :style="commit.branch? {color:commit.branch.color} : undefined"
								| ● 
							.ref v-for="ref of commit.refs" :class="{is_head:ref.name===head_branch,branch:ref.type==='branch'}" v-drag="ref.type==='branch'?ref.name:undefined" v-drop="ref.type==='branch'?branch_drop(ref.name):undefined"
								span :style="{color:ref.color}"
									| {{ ref.name }}
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
		#right.flex-1.col
			selected-commit#selected-commit.active.flex-1.fill-w.padding v-if="selected_commit" :commit="selected_commit" @change="do_log()"
			#resize-hint v-if="selected_commit"
				| ← resize

	popup v-if="drag_drop_target_branch_name" @close="drag_drop_target_branch_name=''"
		.drag-drop-branch-actions.col.center.gap-5
			git-action-button.drag-drop-branch-action v-for="action of drag_drop_branch_actions" :git_action="action" @change="do_log()"
</template>

<script lang="coffee" src="./MainView.coffee"></script>

<style lang="stylus" scoped>
details
	margin 0 0 0 10px
	color grey
	&[open]
		color unset
		padding 10px
.ref
	background black
	font-weight bold
	font-style italic
	display inline
	padding 2px 4px
	border 1px solid #505050
	border-radius 7px
	white-space pre
	&.is_head > *:after
		content ' (HEAD)'
		color white
	&.is_hovered
		outline 3px solid #c54a4a
	&.branch
		&.dragenter
			background white !important
			color red !important
#left
	width calc(100% - 400px)
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
		// ul#branches
		aside#actions
			:deep(button.btn)
				font-size 21px
				padding 0 2px
	> aside#search
		padding 6px
		input#txt-filter
			width 425px
			font-family monospace
			padding 0
			background black
			color #d5983d
		#clear-filter
			position relative
			right 20px
			width 0
			color grey

	.is_head
		box-shadow 0px 0px 6px 4px #ffffff30, 0px 0px 4px 0px #ffffff30 inset
		border-radius 25px

	#log.scroller
		&:focus
			// Need tabindex so that pgUp/Down works consistently (idk why, probably vvs bug), but focus outline adds no value here
			outline none
		.commit
			--h 18px // must be synced with JS
			&.empty
				--h 11px // same
			height var(--h)
			line-height var(--h)
			&.active
				box-shadow 0 0 3px 0px gold
			.vis
				font-weight bold
				font-family monospace
			.info
				cursor pointer
				border-top 1px solid #2e2e2e
				> *
					white-space pre
					overflow hidden
					text-overflow ellipsis
				.subject, .datetime, .hash
					font-family monospace
				> .subject-wrapper
					min-width 150px
					display inline-flex
					> *
						text-overflow ellipsis
					> .ref
						overflow hidden
						flex 0 3 auto
						min-width 55px
						margin 0 1px
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
	#selected-commit
		overflow auto
	#resize-hint
		color #555555
		font-size small
		padding-left 10px

</style>

<style lang="stylus">
.vue-recycle-scroller__item-view.hover > .commit
	background #323232
</style>