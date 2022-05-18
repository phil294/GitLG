<template lang="slm">
#main-view.fill.col
	promise-form#log-input.fill-w.row.center.gap-10 :action="do_log"
		code git 
		input v-model="log_args"
		button →
	pre.padding-l v-if="log_error"
		| Command failed: 
		| {{ log_error }}
	ul#branches.row.align-center
		li.ref.visible v-for="branch of visible_branches"
			button :style="branch.style" @click="scroll_to_branch_tip(branch)"
				| {{ branch.name }}
		li.show-invisible_branches v-if="invisible_branches.length"
			button @click="show_invisible_branches = ! show_invisible_branches"
				| show all >>
		template v-if="show_invisible_branches"
			li.ref.invisible v-for="branch of invisible_branches"
				button :style="branch.style" @click="scroll_to_branch_tip(branch)"
					| {{ branch.name }}
			li Click on any of the branch names to scroll to the tip of it.
	recycle-scroller#commits.scroller.fill-w.flex-1 role="list" :items="commits" :item-size="scroll_item_height" v-slot="{ item: commit }" key-field="i" :buffer="scroll_pixel_buffer" :emit-update="true" @update="commits_scroller_updated" ref="commits_scroller_ref"
		.row.commit
			.vis :style="vis_style"
				span v-for="v of commit.vis" :style="v.style"
					| {{ v.char }}
			.info.flex-1.row.gap-20 v-if="commit.hash" @click="commit_clicked(commit)"
				.subject.flex-1
					.ref v-for="ref of commit.refs" :style="ref.style"
						| {{ ref.name }}
					span {{ commit.subject }}
				.author.flex-noshrink {{ commit.author_name }}
				.datetime.flex-noshrink {{ commit.datetime }}
				button
					.hash.flex-noshrink {{ commit.hash }}
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
	> .ref.visible
		box-shadow 0 0 3px 0px gold
#commits
	.commit
		--h 18px
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
			// > .subject
			// 	> .ref
</style>