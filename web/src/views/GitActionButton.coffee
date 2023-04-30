import { defineComponent } from 'vue'
import { selected_git_action } from './store.coffee'

###* visual representation of a GitAction, resolving to a Button and onclick a Popup with GitInput inside ###
export default defineComponent
	inheritAttrs: false
	props:
		git_action:
			###* @type {() => import('./GitInput.coffee').GitAction} ###
			type: Object
			required: true
	setup: ->
		{ selected_git_action }