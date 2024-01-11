<template lang="slm">
.vis.svg
	svg :height="height" :style="style"
		path.vis-line v-for="line of lines" v-bind="line"
		circle.vis-line v-if="circle" v-bind="circle"
	.refs.row.align-center :style="refs_elems.style"
		ref-tip v-for="ref of refs_elems.refs" :git_ref="ref" :commit="commit" :key="ref.id"
</template>

<script lang="coffee" src="./SVGVisualization.coffee"></script>

<style lang="stylus" scoped>
.vis
	position relative
	line-height 0
	.vis-line
		stroke-width 2
	.refs
		position absolute
		top 50%
		// center vertically
		transform translateY(-50%)
		line-height 1em
		opacity 85%
		z-index 1
	svg
		overflow visible
		> path
			fill none
		> path.vis-line.is_head
			filter drop-shadow(3px 0px 1px rgba(255,255,255,0.3)) drop-shadow(-3px 0px 1px rgba(255,255,255,0.3))
		> circle.vis-line.is_head
			fill white
		> circle.vis-line
			opacity 50%
	&:after
		content ''
		position absolute
		inset 0
		// TODO:
		// box-shadow inset -30px 0 14px -15px #161616
</style>