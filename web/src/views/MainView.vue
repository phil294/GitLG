1<template lang="slm">
#main-view.fill.col
	details
		summary Configure...
		git-input :git_action="log_action" hide_result="" :action="run_log" ref="git_input_ref"
	.row.flex-1
		#log.col.flex-1
			p v-if="!commits.length"
				| No commits found
			nav.row.align-center.justify-space-between.gap-10
				ul#branches.row.align-center.wrap
					li.ref.branch.visible.active v-for="branch of visible_branches" :class="{is_head:branch.name===head_branch, is_hovered:branch.name===hovered_branch_name}"
						button :style="{color:branch.color}" @click="scroll_to_branch_tip(branch)"
							| {{ branch.name }}
					li.show-invisible_branches v-if="invisible_branches.length"
						button @click="show_invisible_branches = ! show_invisible_branches"
							| Show all >>
					template v-if="show_invisible_branches"
						li.ref.branch.invisible v-for="branch of invisible_branches"
							button :style="{color:branch.color}" @click="scroll_to_branch_tip(branch)"
								| {{ branch.name }}
						li Click on any of the branch names to scroll to the tip of it.
				aside#actions.center.gap-5
					input#txt-filter v-if="txt_filter!==null" v-model="txt_filter" placeholder="Type to search for commit summary, hash, author" ref="txt_filter_ref" @keyup.enter="txt_filter_enter($event)"
					label#filter-type-filter.row.align-center v-if="txt_filter!==null"
						input type="radio" v-model="txt_filter_type" value="filter"
						| Filter
					label#filter-type-search.row.align-center v-if="txt_filter!==null"
						input type="radio" v-model="txt_filter_type" value="search"
						| Search
					git-action-button.global-action v-for="action of global_actions" :git_action="action" @change="do_log()"

					button#toggle-txt-filter.btn @click="txt_filter_toggle_dialog()" title="Open search/filter dialog. Also via Ctrl+f" 🔍
					button#refresh.btn @click="do_log()" title="Refresh" ⟳
			recycle-scroller#commits.scroller.fill-w.flex-1 role="list" :items="commits" :item-size="scroll_item_height" v-slot="{ item: commit }" key-field="i" :buffer="scroll_pixel_buffer" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref" tabindex="-1"
				.row.commit :class="commit === selected_commit ? 'active' : null"
					.vis :style="vis_style"
						span.vis-v v-for="v of commit.vis" :style="v.branch? {color:v.branch.color} : undefined" :data-branch-name="v.branch? v.branch.name : undefined"
							| {{ v.char }}
					.info.flex-1.row.gap-20 v-if="commit.hash" @click="commit_clicked(commit)"
						.subject.flex-1
							.ref v-for="ref of commit.refs" :class="{is_head:ref.name===head_branch}"
								span :style="{color:ref.color}"
									| {{ ref.name }}
							span  {{ commit.subject }}
						.author.flex-noshrink {{ commit.author_name }}
						.stats.flex-noshrink.row.align-center.justify-flex-end.gap-5 v-if="commit.stats"
							.changes title="Changed lines in amount of files"
								span: strong {{ commit.stats.insertions + commit.stats.deletions }}
								span.grey  in 
								span.grey {{ commit.stats.files_changed }}
							progress.diff :value="(commit.stats.insertions / (commit.stats.insertions + commit.stats.deletions)) || 0" title="Ratio insertions / deletions"
						.datetime.flex-noshrink {{ commit.datetime }}
						button
							.hash.flex-noshrink {{ commit.hash }}
		#selected-commit.flex-noshrink
			selected-commit.active.padding v-if="selected_commit" :commit="selected_commit" @change="do_log()"
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
	margin 0 5px
	border 1px solid #505050
	border-radius 7px
	white-space pre
	&.is_head:after
		content: ' (HEAD)'
	&.is_hovered
		outline 3px solid #c54a4a
#log
	position relative
	> nav
		margin 5px 0
		position sticky
		top 5px
		z-index 2
		// ul#branches
		aside#actions
			:deep(button.btn)
				font-size 21px
				padding 0 2px
			#toggle-txt-filter.btn
				margin-left 15px
			input#txt-filter
				width 425px
				font-size 12px
				border 2px solid orange

.active
	box-shadow 0 0 3px 0px gold
#commits.scroller
	&:focus
		// Need tabindex so that pgUp/Down works consistently (idk why, probably vvs bug), but focus outline adds no value here
		outline none
	.commit
		--h 22px // must be synced with JS
		height var(--h)
		line-height var(--h)
		.vis
			font-weight bold
			font-size 13px
			font-family 'OverpassMono-Bold', monospace
		.info
			cursor pointer
			> *
				white-space pre
				overflow hidden
				text-overflow ellipsis
			> .subject
				min-width 150px
			.hash, > .datetime
				font-family monospace
			> .datetime, > .author
				color grey
			> .datetime
				font-size 12px
			.stats
				width 120px
#selected-commit
	width 350px
	overflow auto
</style>
<style lang="stylus">
.vue-recycle-scroller__item-view.hover > .commit
	background #323232
</style>