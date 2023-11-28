import { computed, defineComponent } from 'vue'
import { vis_max_amount, head_branch, vis_v_width } from './store.coffee'
import RefTip from './RefTip.vue'
``###* @typedef {import('./log-utils').Commit} Commit ###

export default defineComponent
	props:
		commit:
			required: true
			###* @type {() => Commit} ###
			type: Object
		height:
			required: true
			type: Number
	components: { RefTip }
	# TODO: move more parts of this into log-utils directly so it doesn't need to be recalculated while scrolling? does it matter performance-wise?
	# even html svg elem pre creation?
	setup: (props) ->
		padding_left = 5
		padding_right = 20
		vis_width = computed =>
			vis_max_amount.value * vis_v_width.value + padding_right
		vis_style = computed =>
			'min-width': "max(min(50vw, #{vis_width}px),210px)"
			'max-width': '60vw'
		lines = computed =>
			props.commit.vis_lines.map (vis_line) =>
				d: "M#{padding_left + vis_line.x0 * vis_v_width.value},#{(vis_line.y0 || 0) * props.height} C#{padding_left + (vis_line.xcs || 0) * vis_v_width.value},#{(vis_line.ycs || 0) * props.height} #{padding_left + (vis_line.xce || 0) * vis_v_width.value},#{(vis_line.yce || 0) * props.height} #{padding_left + vis_line.xn * vis_v_width.value},#{(vis_line.yn || 0) * props.height}"
				vis_line: vis_line
				style:
					stroke: vis_line.branch?.color
				class:
					is_head: vis_line.branch?.id == head_branch.value
				# https://stackoverflow.com/q/44040163
				# TODO: Didn't find a working solution yet to fix the gaps between the svg elements.
				'vector-effect': 'non-scaling-stroke'
		branch_line = computed =>
			return null if ! props.commit.branch
			lines.value.find (line) =>
				line.vis_line.branch == props.commit.branch
		circle = computed =>
			return null if ! branch_line.value || ! props.commit.branch
			style:
				stroke: props.commit.branch.color
			class:
				is_head: props.commit.branch.id == head_branch.value
			cx:
				# I guess this could also be calculated more elegantly, but this kind of
				# approximation seems to be good enough for all cases
				padding_left + (branch_line.value.vis_line.x0 + branch_line.value.vis_line.xn + (branch_line.value.vis_line.xcs || 0) + (branch_line.value.vis_line.xce || 0)) / 4 * vis_v_width.value
			cy: props.height * 0.5
			r: 4
		refs_elems = computed =>
			refs: props.commit.refs
			style:
				left: (circle.value?.cx || padding_left) + vis_v_width.value - 2 + 'px'

		{ vis_style, lines, vis_width, circle, refs_elems }