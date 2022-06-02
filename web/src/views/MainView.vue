1<template lang="slm">
#main-view.fill.col
	details
		summary Configure...
		git-input args="log --graph --oneline --pretty=VSCode --author-date-order -n 15000 --skip=0 --all $(git reflog show --format='%h' stash)" :options="[ { name: '--reflog', default: false } ]" title="Git Log" hide_result="" :action="run_log" :immediate="true" ref="git_input_ref"
	.row.flex-1
		#log.col.flex-1
			button#refresh.btn @click="do_log()" ⟳
			input#txt-filter v-if="txt_filter!==null" v-model="txt_filter" placeholder="Type to search for commit summary, hash, author" ref="txt_filter_ref"
			p v-if="!commits.length"
				| No commits found
			ul#branches.row.align-center.wrap
				li.ref.branch.visible.active v-for="branch of visible_branches" :class="{is_head:branch.name===head_branch}"
					/ todo duplicate stuff
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
			recycle-scroller#commits.scroller.fill-w.flex-1 role="list" :items="commits" :item-size="scroll_item_height" v-slot="{ item: commit }" key-field="i" :buffer="scroll_pixel_buffer" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref" tabindex="-1"
				.row.commit :class="commit === selected_commit ? 'active' : null"
					.vis :style="vis_style"
						span v-for="v of commit.vis" :style="v.branch? {color:v.branch.color} : undefined"
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
							progress :value="(commit.stats.insertions / (commit.stats.insertions + commit.stats.deletions)) || 0" title="Ratio insertions / deletions"
						.datetime.flex-noshrink {{ commit.datetime }}
						button
							.hash.flex-noshrink {{ commit.hash }}
		#selected-commit.flex-noshrink
			selected-commit.active.padding v-if="selected_commit" :commit="selected_commit" @change="do_log()"
</template>

<script lang="coffee" src="./MainView.coffee"></script>

<style lang="stylus">
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
ul
	list-style none
	margin 0
#log
	position relative
#refresh.btn
	position absolute
	top 0
	right 0
	z-index 3
	padding 0 2px
	font-size 22px
input#txt-filter
	position absolute
	top 0
	right 50px
	z-index 3
    width 425px
    font-size 12px
    border 2px solid orange
ul#branches
	margin 5px 0
	position sticky
	top 5px
	z-index 2
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
			.hash, > .datetime
				font-family monospace
			> .datetime, > .author
				color grey
			> .datetime
				font-size 12px
			.stats
				width 120px
				> progress
					width 30px
					height 3px

					// somehow both definitions are necessary?
					color #009900
					background-color darkred
					&::-webkit-progress-bar
						background-color darkred
					&::-webkit-progress-value
						background-color #009900
#selected-commit
	width 350px
</style>
<style lang="stylus">
.vue-recycle-scroller__item-view.hover > .commit
	background #323232
</style>