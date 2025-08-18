<template>
	<div :class="{merge:commit.merge}" class="commit-row commit row" role="button">
		<SVGVisualization :commit="commit" :height="calculated_height" :style="vis_style" class="vis" />
		<div v-if="commit.hash" class="info flex-1 row gap-20">
			<div class="subject-wrapper flex-1 row align-center">
				<div :style="commit.branch? {color:commit.branch.color} : undefined" class="vis-ascii-circle vis-resize-handle" @mousedown="vis_resize_handle_mousedown">
					{{ commit.virtual_commit_type ? '○' : '●' }}&nbsp;
				</div>
				<commit-ref-tips class="flex-noshrink" :commit="commit" :allow_wrap="false" :show_buttons="false" />
				<div class="subject">
					&nbsp;{{ commit.subject }}
				</div>
			</div>
			<div :title="commit.author_name+' <'+commit.author_email+'>'" class="author align-center">
				{{ commit.author_name }}
			</div>
			<div class="stats flex-noshrink row align-center justify-flex-end gap-5">
				<template v-if="commit.stats?.files_changed">
					<div class="changes" title="Changed lines in amount of files">
						<span v-if="commit.stats.insertions != null && commit.stats.deletions != null">
							<strong>{{ commit.stats.insertions + commit.stats.deletions }}</strong>
						</span>
						<span class="grey"> in </span>
						<span class="grey">{{ commit.stats.files_changed }}</span>
					</div>
					<progress :value="((commit.stats.insertions || 0) / ((commit.stats.insertions || 0) + (commit.stats.deletions || 0))) || 0" class="diff" title="Ratio insertions / deletions" />
				</template>
			</div>
			<div class="datetime flex-noshrink align-center">
				{{ commit.datetime }}
			</div>
			<button class="flex-noshrink">
				<div :title="commit.hash_long" class="hash">
					{{ commit.hash }}
				</div>
			</button>
		</div>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { vis_width } from '../../../data/store'
import config from '../../../data/store/config'

let props = defineProps({
	commit: {
		required: true,
		/** @type {Vue.PropType<Commit>} */
		type: Object,
	},
	height: { type: Number, default: null },
})

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
let calculated_height = computed(() =>
	props.height || config.get_number('row-height'))
</script>
<style scoped>
.commit-row {
	user-select: none;
}
.info > * {
	white-space: pre;
	overflow: hidden;
	text-overflow: ellipsis;
}
.info .datetime {
	font-family: monospace;
}
.info .hash {
	font-family: monospace;
	min-width: 60px;
}
.info > .subject-wrapper {
	min-width: 150px;
	display: inline-flex;
}
.info > .subject-wrapper:hover {
	overflow: visible;
}
.info > .subject-wrapper > * {
	text-overflow: ellipsis;
}
.info > .subject-wrapper > .subject {
	overflow: hidden;
	/* flex: 1 1 30%; */
}
.info > .subject-wrapper > .vis-resize-handle {
	cursor: col-resize;
}
.vis:hover ~ .info > .subject-wrapper > .commit-ref-tips,
/* Works starting Chrome v129 which VSCode doesn't include *yet*. TODO test once shipped */
.info > .subject-wrapper > .commit-ref-tips:has(~ .author:hover) {
	max-width: 50px;
}
.info > .datetime,
.info > .author {
	color: var(--text-secondary);
}
.info > .datetime {
	font-size: 12px;
}
.info > .author {
	max-width: 150px;
}
.info .stats {
	width: 91px;
}
.commit-row.merge .subject {
	color: var(--text-secondary);
}
</style>
