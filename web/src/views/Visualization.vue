<template lang="slm">
.vis :style="vis_style"
	svg :width="vis_width" :height="v_height"
		line.vis-v v-for="line of lines" v-bind="line"
		circle.vis-v v-if="circle" v-bind="circle"
	.refs.row.align-center :style="refs_elems.style"
		.ref v-for="ref_elem of refs_elems.refs" v-drag="ref_elem.ref.type==='branch'?ref_elem.ref.name:undefined" v-drop="ref_elem.ref.type==='branch'?$emit('branch_drop',ref_elem.ref.name):undefined" v-bind="ref_elem.bind"
			| {{ ref_elem.ref.name }}
</template>

<script lang="coffee" src="./Visualization.coffee"></script>

<style lang="stylus" scoped>
.vis
	position relative
	line-height 0
	.vis-v
		stroke-width 2
	.refs
		position absolute
		top 0
		line-height 1em
		opacity 85%
		font-family unset
	svg
		> line.vis-v.is_head
			filter drop-shadow(4px 0px 1px #ffffffdd) drop-shadow(-4px 0px 1px #ffffffdd)
		> circle.vis-v.is_head
			fill white
</style>