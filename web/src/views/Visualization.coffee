import { computed, defineComponent } from 'vue'
``###* @typedef {import('./log-utils').Commit} Commit ###

export default defineComponent
	props:
		commit:
			required: true
			###* @type {() => Commit} ###
			type: Object
		vis_max_length:
			required: true
			type: Number
		head_branch:
			required: true
			type: String
	emits: ['branch_drop']
	setup: (props) ->
		v_width = 7
		padding_left = 5
		padding_right = 20
		vis_width = props.vis_max_length * v_width + padding_right
		v_height = computed =>
			props.commit.scroll_height
		vis_style = computed =>
			'min-width': "max(min(50vw, #{vis_width}px),210px)"
		lines = computed =>
			props.commit.vis
				.map (v, i) =>
					return null if v.char == ' '
					coords = switch v.char
						when '*', '|'
							x1: padding_left + v_width * (i + 0.5)
							x2: padding_left + v_width * (i + 0.5)
							y1: 0
							y2: v_height.value
						when '⎺*', '⎺|'
							x1: padding_left + v_width * i
							x2: padding_left + v_width * (i + 0.5)
							y1: 0
							y2: v_height.value
						when '*⎺', '|⎺'
							x1: padding_left + v_width * (i + 1)
							x2: padding_left + v_width * (i + 0.5)
							y1: 0
							y2: v_height.value
						when '_'
							x1: padding_left + v_width * i
							x2: padding_left + v_width * (i + 1)
							y1: v_height.value
							y2: v_height.value
						when '\\'
							x1: padding_left + v_width * i
							x2: padding_left + v_width * (i + 1)
							y1: 0
							y2: v_height.value
						when '⎺\\'
							x1: padding_left + v_width * (i - 0.5)
							x2: padding_left + v_width * (i + 1)
							y1: 0
							y2: v_height.value
						when '⎺\\⎽'
							x1: padding_left + v_width * (i - 0.5)
							x2: padding_left + v_width * (i + 1.5)
							y1: 0
							y2: v_height.value
						when '/'
							x1: padding_left + v_width * i
							x2: padding_left + v_width * (i + 1)
							y1: v_height.value
							y2: 0
						when '/⎺'
							x1: padding_left + v_width * i
							x2: padding_left + v_width * (i + 1.5)
							y1: v_height.value
							y2: 0
						when '.', '-'
							x1: padding_left + v_width * i
							x2: padding_left + v_width * (i + 1)
							y1: 0
							y2: 0
						else
							throw new Error 'unexpected vis char '+v.char
					{
						style:
							stroke: v.branch?.color
						class:
							is_head: v.branch?.name == props.head_branch
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
					is_head: v.branch?.name == props.head_branch
				cx: padding_left + v_width * (vis_circle_index.value + 0.5)
				cy: v_height.value * 0.5
				r: 4
		refs_elems = computed =>
			refs:
				props.commit.refs.map (ref) =>
					ref: ref
					bind:
						style:
							color: ref.color
						class:
							is_head: ref.name == props.head_branch
							'branch-tip': ref.type == 'branch'
			style:
				left: padding_left + v_width * (vis_circle_index.value + 1) + 3 + 'px'

		{ vis_style, lines, vis_width, circle, refs_elems, v_height }