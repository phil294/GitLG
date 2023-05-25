import { computed, defineComponent } from 'vue'
import { exchange_message } from '../bridge.coffee'

``###*
# @typedef {{
#	path: string
#	insertions: number
#	deletions: number
# }} FileDiff
###

export default defineComponent
	emits: ['show_diff', 'view_ref']
	props:
		files:
			###* @type {() => FileDiff[]} ###
			type: Array
			required: true
	setup: (props) ->
		files = computed =>
			props.files.map (file) => {
				...file
				filename: file.path.split('/').at(-1) or '?'
				dir: file.path.split('/').slice(0, -1).join('/')
			}
		open_file = (###* @type string ### filepath) =>
			exchange_message 'open-file',
				filename: filepath

		{
			open_file
			files
		}