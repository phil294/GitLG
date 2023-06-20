<template lang="slm">
.vis.ascii.row.align-center :style="vis_style"
	span.vis-v v-for="v of vis" v-bind="v"
		| {{ v.char }}
	.refs
		ref-tip v-for="ref of commit.refs" :git_ref="ref" :commit="commit" :key="ref.id"
</template>

<script lang="coffee" src="./ASCIIVisualization.coffee"></script>

<style lang="stylus" scoped>
.vis-v
	font-weight bold
	font-family monospace
	white-space pre
.refs
	line-height 1em
	opacity 85%
</style>