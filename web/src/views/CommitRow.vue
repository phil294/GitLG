<template lang="slm">
.commit.row :class="{merge:commit.merge}"
	SVGVisualization.vis :height="height" :commit="commit" :style="vis_style"
	.info.flex-1.row.gap-20 v-if="commit.hash"
		.subject-wrapper.flex-1.row.align-center
			.vis-ascii-circle.vis-resize-handle :style="commit.branch? {color:commit.branch.color} : undefined" @mousedown="vis_resize_handle_mousedown"
				| ●&nbsp;
			.subject  {{ commit.subject }}
		.author.flex-noshrink.align-center :title="commit.author_name+' <'+commit.author_email+'>'"
			| {{ commit.author_name }}
		.stats.flex-noshrink.row.align-center.justify-flex-end.gap-5
			.changes v-if="commit.stats" title="Changed lines in amount of files"
				span: strong {{ commit.stats.insertions + commit.stats.deletions }}
				span.grey  in
				span.grey {{ commit.stats.files_changed }}
			progress.diff v-if="commit.stats" :value="(commit.stats.insertions / (commit.stats.insertions + commit.stats.deletions)) || 0" title="Ratio insertions / deletions"
		.datetime.flex-noshrink.align-center {{ commit.datetime }}
		button
			.hash.flex-noshrink :title="commit.hash_long" {{ commit.hash }}
</template>

<script lang="coffee">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { branches, history, commits, config, vis_width } from './store.coffee'
import RefTip from './RefTip.vue'
import SVGVisualization from './SVGVisualization.vue'
###* @typedef {import('./log-utils').Commit} Commit ###

export default
	components: { SVGVisualization }
	props:
		commit:
			required: true
			###* @type {() => Commit} ###
			type: Object
		height:
			type: Number
	setup: (props) ->
		vis_min_width = 15
		vis_max_width_vw = 90
		vis_style = computed =>
			width: vis_width.value + 'px'
			'max-width': vis_max_width_vw + 'vw'
			'min-width': vis_min_width + 'px'
		vis_resize_handle_mousedown = (###* @type MouseEvent ### mousedown_event) =>
			vis_max_width = window.innerWidth * vis_max_width_vw / 100
			start_x = mousedown_event.x
			start_width = vis_width.value
			on_mousemove = (###* @type MouseEvent ### mousemove_event) =>
				window.requestAnimationFrame =>
					vis_width.value = Math.min(vis_max_width, Math.max(vis_min_width,
						start_width + mousemove_event.x - start_x))
			document.addEventListener 'mousemove', on_mousemove
			document.addEventListener 'mouseup', ((mouseup_event) =>
				mouseup_event.preventDefault() # Not sure why this doesn't work
				document.removeEventListener 'mousemove', on_mousemove
			), { capture: true, once: true }
		height = computed =>
			props.height || config.value['row-height']
		{
			vis_style
			vis_resize_handle_mousedown
			height
		}
</script>

<style lang="stylus" scoped>
.commit
	user-select none
	.info
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
			> .vis-resize-handle
				cursor col-resize
		> .datetime, > .author
			color grey
		> .datetime
			font-size 12px
		> .author
			max-width 150px
		.stats
			width 91px
	&.merge .subject
		color grey
</style>