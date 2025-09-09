<template>
	<div :class="{merge:commit.merge}" class="commit-row commit row" role="button">
		<SVGVisualization :commit="commit" :height="calculated_height" :style="vis_style" class="vis" />
		<div v-if="commit.hash" class="info flex-1 row gap-20">
			<div class="subject-wrapper flex-1 row align-center">
				<div :style="commit.branch? {color:commit.branch.color} : undefined" class="vis-ascii-circle vis-resize-handle" @mousedown="vis_resize_handle_mousedown">
					{{ commit.virtual_commit_type ? '○' : '●' }}&nbsp;
				</div>
				<commit-ref-tips class="flex-noshrink" :commit="commit" :allow_wrap="false" :show_buttons="false" />
				<div class="subject" @dblclick.stop="on_subject_dblclick">
					&nbsp;{{ commit.subject }}
				</div>
			</div>
			<div :title="commit.author_name+' <'+commit.author_email+'>'" class="author align-center row gap-8 flex-noshrink">
				<div v-if="commit.author_email" class="avatar-placeholder" :class="{loading: !author_avatar}">
					<img v-if="author_avatar" :src="author_avatar" class="avatar" alt="">
					<div v-else class="avatar-initial">
						{{ commit.author_name?.[0]?.toUpperCase() || '?' }}
					</div>
				</div>
				<div class="author-name">
					{{ commit.author_name }}
				</div>
			</div>
			<template v-if="commit.stats?.files_changed">
				<div class="stats flex-noshrink row align-center justify-flex-end gap-5">
					<div class="changes" title="Changed lines in amount of files">
						<span v-if="commit.stats.insertions != null && commit.stats.deletions != null">
							<strong>{{ commit.stats.insertions + commit.stats.deletions }}</strong>
						</span>
						<span class="grey"> in </span>
						<span class="grey">{{ commit.stats.files_changed }}</span>
					</div>
					<progress :value="((commit.stats.insertions || 0) / ((commit.stats.insertions || 0) + (commit.stats.deletions || 0))) || 0" class="diff" title="Ratio insertions / deletions" />
				</div>
			</template>
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
import { computed, ref, onMounted, watch } from 'vue'
import { vis_width, selected_git_action } from '../../../data/store'
import config from '../../../data/store/config'
import { get_avatar } from '../../../utils/gravatar'
import { commit_actions } from '../../../data/store/actions'

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

let author_avatar = ref(/** @type {string|null} */ (null))

async function load_avatar() {
	if (! props.commit.author_email) {
		author_avatar.value = null
		return
	}

	try {
		let avatar_data = await get_avatar(props.commit.author_email)
		author_avatar.value = avatar_data
	} catch (e) {
		console.warn('Failed to load avatar:', e)
		author_avatar.value = null
	}
}

onMounted(() => {
	load_avatar()
})

watch(() => props.commit.author_email, () => {
	load_avatar()
})

function on_subject_dblclick() {
	if (! props.commit?.hash)
		return
	// First commit action is checkout
	selected_git_action.value = commit_actions(props.commit.hash).value[0] || null
}
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
	flex: 3 1 0;
	min-width: 150px;
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
	text-align: left;
	justify-content: flex-start;
	display: flex;
	width: 150px;
	min-width: 150px;
}
.info > .author {
	flex: 1 1 0;
	text-align: left;
	justify-content: flex-start;
	align-items: center;
}
.avatar-placeholder {
	width: 16px;
	height: 16px;
	border-radius: 50%;
	flex-shrink: 0;
	position: relative;
	overflow: hidden;
	margin-right: 4px;
}
.avatar {
	width: 100%;
	height: 100%;
	border-radius: 50%;
}
.avatar-initial {
	width: 100%;
	height: 100%;
	background: var(--text-secondary);
	color: var(--background);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 9px;
	font-weight: bold;
	border-radius: 50%;
}
.avatar-placeholder.loading .avatar-initial {
	opacity: 0.6;
}
.author-name {
	overflow: hidden;
	text-overflow: ellipsis;
}
.info .stats {
	width: 91px;
}
.commit-row.merge .subject {
	color: var(--text-secondary);
}
</style>
