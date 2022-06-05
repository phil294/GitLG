import { ref, defineComponent } from 'vue'
import GitInput from './GitInput.vue'

###* visual representation of a GitAction, resolving to a Button and onclick a Popup with GitInput inside ###
export default defineComponent
	inheritAttrs: false
	components: { GitInput }
	emits: [ 'change' ]
	props:
		git_action:
			###* @type {() => import('./GitInput.coffee').GitAction} ###
			type: Object
			required: true
	setup: (_, { emit }) ->
		show_popup = ref false
		keep_open = ref false
		
		success = =>
			if not keep_open.value
				show_popup.value = false
			emit 'change'

		{
			show_popup
			keep_open
			success
		}