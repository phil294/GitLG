<template>
	<div class="vis svg">
		<svg :height="height" :style="style">
			<path v-for="line, i of lines" :key="i" class="vis-line" v-bind="line" />
			<circle v-if="circle" class="vis-line" v-bind="circle" />
		</svg>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { head_branch, vis_v_width } from '../state/store.js'

let props = defineProps({
	commit: {
		required: true,
		/** @type {Vue.PropType<Commit>} */
		type: Object,
	},
	height: { required: true, type: Number },
	style: { type: Object, default: () => {} },
})

let padding_left = 5
let lines = computed(() =>
	props.commit.vis_lines.map((vis_line) => ({
		d: `M${padding_left + vis_line.x0 * vis_v_width.value},${(vis_line.y0 || 0) * props.height} C${padding_left + (vis_line.xcs || 0) * vis_v_width.value},${(vis_line.ycs || 0) * props.height} ${padding_left + (vis_line.xce || 0) * vis_v_width.value},${(vis_line.yce || 0) * props.height} ${padding_left + vis_line.xn * vis_v_width.value},${(vis_line.yn || 0) * props.height}`,
		vis_line,
		style: {
			stroke: vis_line.branch?.color,
		},
		class: {
			is_head: vis_line.branch?.id === head_branch.value,
		},
	})))
let branch_line = computed(() => {
	if (! props.commit.branch)
		return null
	return lines.value.find((line) =>
		line.vis_line.branch === props.commit.branch)
})
let circle = computed(() => {
	if (! branch_line.value || ! props.commit.branch)
		return null
	return {
		style: {
			stroke: props.commit.branch.color,
		},
		class: {
			is_head: props.commit.branch.id === head_branch.value,
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
.vis svg > circle {
	fill: var(--vscode-editor-background);
}
.vis svg > path.vis-line.is_head {
	filter: drop-shadow(3px 0px 1px rgb(from var(--vscode-editor-foreground) r g b / 0.3)) drop-shadow(-3px 0px 1px rgb(from var(--vscode-editor-foreground) r g b / 0.3));
}
.vis svg > circle.vis-line.is_head {
	fill: var(--vscode-editor-foreground);
}
</style>
