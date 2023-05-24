import { computed, defineComponent } from 'vue'
import { vis_max_length, head_branch } from './store.coffee'
import RefTip from './RefTip.vue'
``###* @typedef {import('./log-utils').Commit} Commit ###

export default defineComponent
	props:
		commit:
			required: true
			###* @type {() => Commit} ###
			type: Object
	components: { RefTip }
	setup: (props) ->
		vis_v_width = 10
		vis_width = vis_max_length.value * vis_v_width
		v_height = computed =>
			props.commit.scroll_height
		vis_style = computed =>
			'min-width': "max(min(50vw, #{vis_width}px),210px)"
			'max-width': '60vw'
			height: "#{v_height.value}px"
		vis = computed =>
			props.commit.vis
				.map (v, i) =>
					char = switch v.char
						when '⎺*', '*⎺', '⎽*', '*⎽' then '*'
						when '⎺|', '|⎺', '⎽|', '|⎽', '⎽⎽|', '|⎽⎽' then '|'
						when '⎺\\', '⎺\\⎽' then '\\'
						when '/⎺' then '/'
						else v.char
					{
						style:
							color: v.branch?.color
						class:
							is_head: v.branch?.id == head_branch.value
						char
					}

		{ vis_style, vis, v_height }