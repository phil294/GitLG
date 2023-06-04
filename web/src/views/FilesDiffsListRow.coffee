import { computed, defineComponent } from 'vue'
import { exchange_message } from '../bridge.coffee'
``###* @typedef {import('./FilesDiffsList.coffee').FileDiff} FileDiff ###

export default defineComponent
	emits: ['show_diff', 'view_ref']
	props:
		file:
			###* @type {() => FileDiff} ###
			type: Object
			required: true
	setup: (props) ->
		open_file = (###* @type string ### filepath) =>
			exchange_message 'open-file',
				filename: filepath

		{
			open_file
		}