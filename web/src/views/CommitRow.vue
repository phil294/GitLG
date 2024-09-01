<template>
	<div :class="{merge:commit.merge}" class="commit row">
		<SVGVisualization :commit="commit" :height="height" :style="vis_style" class="vis" />
		<div v-if="commit.hash" class="info flex-1 row gap-20">
			<div class="subject-wrapper flex-1 row align-center">
				<div :style="commit.branch? {color:commit.branch.color} : undefined" class="vis-ascii-circle vis-resize-handle" @mousedown="vis_resize_handle_mousedown">
					●&nbsp;
				</div>
				<div class="subject">
					{{ commit.subject }}
				</div>
			</div>
			<div :title="commit.author_name+' <'+commit.author_email+'>'" class="author flex-noshrink align-center">
				{{ commit.author_name }}
			</div>
			<div class="stats flex-noshrink row align-center justify-flex-end gap-5">
				<div v-if="commit.stats" class="changes" title="Changed lines in amount of files">
					<span>
						<strong>{{ commit.stats.insertions + commit.stats.deletions }}</strong>
					</span>
					<span class="grey"> in</span>
					<span class="grey">{{ commit.stats.files_changed }}</span>
				</div>
				<progress v-if="commit.stats" :value="(commit.stats.insertions / (commit.stats.insertions + commit.stats.deletions)) || 0" class="diff" title="Ratio insertions / deletions" />
			</div>
			<div class="datetime flex-noshrink align-center">
				{{ commit.datetime }}
			</div>
			<button>
				<div :title="commit.hash_long" class="hash flex-noshrink">
					{{ commit.hash }}
				</div>
			</button>
		</div>
	</div>
</template>
<script>
import { computed } from 'vue'
import { config, vis_width } from './store.js'

export default {
	props: {
		commit: {
			required: true,
			/** @type {() => Commit} */
			type: Object,
		},
		height: { type: Number },
	},
	setup(props) {
		let vis_min_width = 15
		let vis_max_width_vw = 90
		let vis_style = computed(() => ({
			width: vis_width.value + 'px',
			'max-width': vis_max_width_vw + 'vw',
			'min-width': vis_min_width + 'px',
		}))
		function vis_resize_handle_mousedown(/** @type {MouseEvent} */ mousedown_event) {
			let vis_max_width = window.innerWidth * vis_max_width_vw / 100
			let start_x = mousedown_event.x
			let start_width = vis_width.value
			function on_mousemove(/** @type {MouseEvent} */ mousemove_event) {
				window.requestAnimationFrame(() => {
					vis_width.value = Math.min(vis_max_width, Math.max(vis_min_width, start_width + mousemove_event.x - start_x))
				})
			}
			document.addEventListener('mousemove', on_mousemove)
			document.addEventListener('mouseup', (mouseup_event) => {
				mouseup_event.preventDefault() // Not sure why this doesn't work
				document.removeEventListener('mousemove', on_mousemove)
			}, { capture: true, once: true })
		}
		let height = computed(() =>
			props.height || config.value['row-height'])

		return {
			vis_style,
			vis_resize_handle_mousedown,
			height,
		}
	},
}
</script>
<style scoped>
.commit {
	user-select: none;
}
.commit .info > * {
	white-space: pre;
	overflow: hidden;
	text-overflow: ellipsis;
}
.commit .info .datetime,
.commit .info .hash {
	font-family: monospace;
}
.commit .info > .subject-wrapper {
	min-width: 150px;
	display: inline-flex;
}
.commit .info > .subject-wrapper > * {
	text-overflow: ellipsis;
}
.commit .info > .subject-wrapper > .subject {
	overflow: hidden;
	flex: 1 1 30%;
}
.commit .info > .subject-wrapper > .vis-resize-handle {
	cursor: col-resize;
}
.commit .info > .datetime,
.commit .info > .author {
	color: #808080;
}
.commit .info > .datetime {
	font-size: 12px;
}
.commit .info > .author {
	max-width: 150px;
}
.commit .info .stats {
	width: 91px;
}
.commit.merge .subject {
	color: #808080;
}
</style>
