<template lang="slm">
#main-view.fill.col
	promise-form#log-input.fill-w.row.center.gap-10 :action="do_log"
		code git 
		input v-model="log_args"
		button →
	pre.padding-l v-if="log_error"
		| Command failed: 
		| {{ log_error }}
	ul#refs.row.col-gap-10 tabindex="-1"
		li.ref v-for="ref of refs" :style="ref.style"
			| {{ ref.name }}
	recycle-scroller#commits.scroller.fill-w.flex-1 :items="commits" :item-size="18" v-slot="{ item: commit }" key-field="i" role="list"
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

<script lang="coffee">
import store from '../store.coffee'
import colors from '../colors.coffee'
import * as log_utils from '../log-utils.coffee'
import { ref, nextTick } from 'vue'

export default
	setup: ->
		log_args = ref "log --graph --oneline --pretty=VSCode --author-date-order -n 15000 --skip=0 --all $(git reflog show --format='%h' stash)"
		log_error = ref ''
		commits = ref []
		refs = ref []
		vis_style = ref ''
		### Performance bottlenecks, in this order: Renderer (solved with virtual scroller, now always only a few ms), git cli (depends on both repo size and -n option and takes between 0 and 30 seconds, only because of its --graph computation), processing/parsing/transforming is about 1%-20% of git ###
		do_log = =>
			log_error.value = ''
			commits.value = []
			sep = '^%^%^%^%^'
			args = log_args.value.replace(" --pretty=VSCode", " --pretty=format:'#{sep}%h#{sep}%an#{sep}%ae#{sep}%at#{sep}%D#{sep}%s'")
			try
				data = await store.do_git args
			catch e
				console.warn e
				log_error.value = JSON.stringify e, null, 4
				return
			parsed = log_utils.parse data, sep
			color_by_ref = parsed.refs.reduce (all, ref, i) =>
				all[ref] = colors[i % 191]
				all
			, {}
			commits.value = parsed.commits.map (c, i) => {
				...c
				i
				refs: c.refs.map (ref) =>
					name: ref
					style: color: color_by_ref[ref]
				datetime: if c.timestamp then new Date(c.timestamp).toISOString().slice(0,19).replace("T"," ") else undefined
				vis: c.vis.map (v) =>
					char: v.char
					style: color: color_by_ref[v.ref]
			}
			refs.value = parsed.refs
				.filter (ref) =>
					not ref.startsWith "virtual_branch_"
				.map (ref) =>
					name: ref
					style: color: color_by_ref[ref]
				.slice(0, 150)
			vis_style.value = 'min-width': "min(50vw, #{parsed.vis_max_length}em"
		
		do_log()

		commit_clicked = (commit) =>
		
		{
			commits
			refs # todo: if omitting this, no error is shown in webview, but in local serve it is??
			vis_style
			do_log
			log_args
			log_error
			commit_clicked
		}
</script>

<style lang="stylus">
#log-input
	input
		padding 0 7px
ul
	list-style none
	margin 0
#refs
	margin 5px 0
	position sticky
	top 5px
	z-index 2
	flex-wrap wrap
	max-height 27px
	overflow hidden
	&:focus
		max-height unset
	> .ref
		background black
		border 1px solid #505050
		box-shadow 0 0 3px 0px gold
		padding 2px 4px
		border-radius 7px
		font-weight bold
		font-style italic
		white-space pre
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
			> .subject
				> .ref
					padding 2px 4px
					font-style italic
					font-weight bold
					display inline
</style>