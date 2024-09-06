<template>
	<div class="vis svg">
		<svg :height="height" :style="style">
			<path v-for="line, i of lines" :key="i" class="vis-line" v-bind="line" />
			<circle v-if="circle" class="vis-line" v-bind="circle" />
		</svg>
		<div :style="refs_elems.style" class="refs row align-center">
			<ref-tip v-for="ref of refs_elems.refs" :key="ref.id" :commit="commit" :git_ref="ref" />
		</div>
	</div>
</template>
<script src="./SVGVisualization"></script>
<style scoped>
.vis {
	position: relative;
	line-height: 0;
}
.vis .vis-line {
	stroke-width: 2;
}
.vis .refs {
	position: absolute;
	top: 50%;
	transform: translateY(-50%);
	line-height: 1em;
	opacity: 85%;
	z-index: 1;
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
