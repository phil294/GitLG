import { computed, defineComponent } from 'vue'
import { vis_max_length, head_branch, vis_v_width } from './store.coffee'
import RefTip from './RefTip.vue'
``###* @typedef {import('./log-utils').Commit} Commit ###

export default defineComponent
	props:
		commit:
			required: true
			###* @type {() => Commit} ###
			type: Object
	emits: ['branch_drop']
	components: { RefTip }
	setup: (props) ->
		padding_left = 5
		padding_right = 20
		vis_width = vis_max_length.value * vis_v_width.value + padding_right
		v_height = computed =>
			props.commit.scroll_height
		vis_style = computed =>
			'min-width': "max(min(50vw, #{vis_width}px),210px)"
			'max-width': '60vw'
		lines = computed =>
			props.commit.vis
				.map (v, i) =>
					return null if v.char == ' '
					coords = switch v.char
						when '*', '|'
							x1: padding_left + vis_v_width.value * (i + 0.5)
							x2: padding_left + vis_v_width.value * (i + 0.5)
							y1: 0
							y2: v_height.value
						when '⎺*', '⎺|'
							x1: padding_left + vis_v_width.value * i
							x2: padding_left + vis_v_width.value * (i + 0.5)
							y1: 0
							y2: v_height.value
						when '*⎺', '|⎺'
							x1: padding_left + vis_v_width.value * (i + 1)
							x2: padding_left + vis_v_width.value * (i + 0.5)
							y1: 0
							y2: v_height.value
						when '⎽*', '⎽|'
							x1: padding_left + vis_v_width.value * (i + 0.5)
							x2: padding_left + vis_v_width.value * i
							y1: 0
							y2: v_height.value
						when '⎽⎽|'
							x1: padding_left + vis_v_width.value * (i - 0.5)
							x2: padding_left + vis_v_width.value * (i + 0.5)
							y1: v_height.value
							y2: 0
						when '*⎽', '|⎽'
							x1: padding_left + vis_v_width.value * (i + 0.5)
							x2: padding_left + vis_v_width.value * (i + 1)
							y1: 0
							y2: v_height.value
						when '|⎽⎽'
							x1: padding_left + vis_v_width.value * (i + 0.5)
							x2: padding_left + vis_v_width.value * (i + 1.5)
							y1: 0
							y2: v_height.value
						when '_'
							x1: padding_left + vis_v_width.value * i
							x2: padding_left + vis_v_width.value * (i + 1)
							y1: v_height.value
							y2: v_height.value
						when '\\'
							x1: padding_left + vis_v_width.value * i
							x2: padding_left + vis_v_width.value * (i + 1)
							y1: 0
							y2: v_height.value
						when '⎺\\'
							x1: padding_left + vis_v_width.value * (i - 0.5)
							x2: padding_left + vis_v_width.value * (i + 1)
							y1: 0
							y2: v_height.value
						when '⎺\\⎽'
							x1: padding_left + vis_v_width.value * (i - 0.5)
							x2: padding_left + vis_v_width.value * (i + 1.5)
							y1: 0
							y2: v_height.value
						when '/'
							x1: padding_left + vis_v_width.value * (i + 1)
							x2: padding_left + vis_v_width.value * i
							y1: 0
							y2: v_height.value
						when '/⎺'
							x1: padding_left + vis_v_width.value * (i + 1.5)
							x2: padding_left + vis_v_width.value * i
							y1: 0
							y2: v_height.value
						when '.', '-'
							x1: padding_left + vis_v_width.value * i
							x2: padding_left + vis_v_width.value * (i + 1)
							y1: 0
							y2: 0
						else
							throw new Error 'unexpected vis char '+v.char
					{
						style:
							stroke: v.branch?.color
						class:
							is_head: v.branch?.id == head_branch.value
						...coords
					}
				.filter Boolean
		vis_circle_index = computed =>
			props.commit.vis.findIndex (v) =>
				['*', '⎺*', '*⎺'].includes v.char
		circle = computed =>
			if vis_circle_index.value > -1
				v = props.commit.vis[vis_circle_index.value]
				style:
					stroke: v.branch?.color
				class:
					is_head: v.branch?.id == head_branch.value
				cx: padding_left + vis_v_width.value * (vis_circle_index.value + 0.5)
				cy: v_height.value * 0.5
				r: 4
		refs_elems = computed =>
			refs: props.commit.refs
			style:
				left: padding_left + vis_v_width.value * (vis_circle_index.value + 1) + 3 + 'px'

		{ vis_style, lines, vis_width, circle, refs_elems, v_height }