<template lang="slm">
#main-view.fill.col
	promise-form#log-input.fill-w.row.center.gap-10 :action="do_log"
		code git 
		input v-model="log_args"
		button →
	pre.padding-l v-if="log_error"
		| Command failed: 
		| {{ log_error }}
	.row.flex-1
		#log.col.flex-1
			ul#branches.row.align-center
				li.ref.visible.active v-for="branch of visible_branches"
					/ todo duplicate stuff
					button :style="{color:branch.color}" @click="scroll_to_branch_tip(branch)"
						| {{ branch.name }}
				li.show-invisible_branches v-if="invisible_branches.length"
					button @click="show_invisible_branches = ! show_invisible_branches"
						| Show all >>
				template v-if="show_invisible_branches"
					li.ref.invisible v-for="branch of invisible_branches"
						button :style="{color:branch.color}" @click="scroll_to_branch_tip(branch)"
							| {{ branch.name }}
					li Click on any of the branch names to scroll to the tip of it.
			recycle-scroller#commits.scroller.fill-w.flex-1 role="list" :items="commits" :item-size="scroll_item_height" v-slot="{ item: commit }" key-field="i" :buffer="scroll_pixel_buffer" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref"
				.row.commit :class="commit === active_commit ? 'active' : null"
					.vis :style="vis_style"
						span v-for="v of commit.vis" :style="v.branch? {color:v.branch.color} : undefined"
							| {{ v.char }}
					.info.flex-1.row.gap-20 v-if="commit.hash" @click="commit_clicked(commit)"
						.subject.flex-1
							.ref v-for="ref of commit.refs" :style="{color:ref.color}"
								| {{ ref.name }}
							span {{ commit.subject }}
						.author.flex-noshrink {{ commit.author_name }}
						.stats.flex-noshrink.row.align-center.justify-flex-end.gap-5 v-if="commit.stats"
							.changes title="Changed lines in amount of files"
								span: strong {{ commit.stats.insertions + commit.stats.deletions }}
								span.grey  in 
								span.grey {{ commit.stats.files_changed }}
							progress :value="commit.stats.insertions / (commit.stats.insertions + commit.stats.deletions)" title="Ratio insertions / deletions"
						.datetime.flex-noshrink {{ commit.datetime }}
						button
							.hash.flex-noshrink {{ commit.hash }}
		#active-commit.active.flex-noshrink.padding
			pre v-if="active_commit"
				h2.summary {{ active_commit.summary }}
</template>

<script lang="coffee" src="./MainView.coffee"></script>

<style lang="stylus">
#log-input
	input
		padding 0 7px
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
ul
	list-style none
	margin 0
#branches
	margin 5px 0
	position sticky
	top 5px
	z-index 2
	flex-wrap wrap
.active
	box-shadow 0 0 3px 0px gold
#commits
	.commit
		--h 22px
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
#active-commit
	width 350px
	h2.summary
		white-space pre
		overflow hidden
		text-overflow ellipsis
</style>
<style lang="stylus">
.vue-recycle-scroller__item-view.hover > .commit
	background #323232
</style>