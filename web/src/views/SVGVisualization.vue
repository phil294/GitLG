<template>
	<div class="vis svg">
		<!-- +1 avoids gaps between rows in certain zoom levels -->
		<svg :height="height+1" :style="style">
			<path v-for="line, i of lines" :key="i" class="vis-line" v-bind="line" stroke-linecap="round" />
			<circle v-if="circle" class="vis-line" v-bind="circle" />
		</svg>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { branch_by_id, head_branch, vis_v_width } from '../state/store.js'

let props = defineProps({
	commit: {
		required: true,
		/** @type {Vue.PropType<Commit>} */
		type: Object,
	},
	height: { required: true, type: Number },
	style: { type: Object, default: () => {} },
})

let commit_branch = computed(() =>
	branch_by_id(props.commit.branch_id || ''))

let padding_left = 5
let lines = computed(() =>
	props.commit.vis_lines.map((vis_line) => {
		// TODO: test performance by this lookup in massive scrolling and otherwise duplicate color onto vis line directly in log parser
		let branch = branch_by_id(vis_line.branch_id || '')
		return {
			d: `M${padding_left + vis_line.x0 * vis_v_width.value},${(vis_line.y0 || 0) * props.height} C${padding_left + (vis_line.xcs || 0) * vis_v_width.value},${(vis_line.ycs || 0) * props.height} ${padding_left + (vis_line.xce || 0) * vis_v_width.value},${(vis_line.yce || 0) * props.height} ${padding_left + vis_line.xn * vis_v_width.value},${(vis_line.yn || 0) * props.height}`,
			vis_line,
			style: {
				stroke: branch?.color,
			},
			class: {
				is_head: vis_line.branch_id === head_branch.value,
			},
		}
	}))
let branch_line = computed(() => {
	if (! props.commit.branch_id)
		return null
	return lines.value.find((line) =>
		line.vis_line.branch_id === props.commit.branch_id)
})
let circle = computed(() => {
	if (! branch_line.value || ! commit_branch.value)
		return null
	return {
		style: {
			stroke: commit_branch.value.color,
		},
		class: {
			is_head: props.commit.branch_id === head_branch.value,
		},
		cx:
			// branch_line is the first of the 1 to 2 lines per row per branch, so the upper one,
			// which runs into (=xn) the circle
			padding_left + branch_line.value.vis_line.xn * vis_v_width.value,
		cy: props.height * 0.5,
		r: 4,
	}
})
</script>
<style scoped>
.vis {
	position: relative;
	line-height: 0;
}
.vis .vis-line {
	stroke-width: 2;
}
.vis svg > path {
	fill: none;
}
.vis svg > path.vis-line.is_head {
	filter: drop-shadow(3px 0px 1px rgba(255,255,255,0.3)) drop-shadow(-3px 0px 1px rgba(255,255,255,0.3));
}
.vis svg > circle.vis-line.is_head {
	fill: #fff;
}
.vis:after {
	content: '';
	position: absolute;
	inset: 0;
}
</style>
