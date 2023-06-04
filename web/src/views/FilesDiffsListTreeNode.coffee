import { computed, defineComponent } from 'vue'
import FilesDiffsListRow from './FilesDiffsListRow.vue'

``###* @typedef {import('./FilesDiffsList.coffee').TreeNode} TreeNode ###

export default defineComponent
	components: { FilesDiffsListRow }
	props:
		node:
			###* @type {() => TreeNode} ###
			type: Object
			required: true
	setup: (props) ->
		{

		}