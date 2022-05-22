import { git } from '../store.coffee'
import { ref, computed, defineComponent, reactive, watchEffect } from 'vue'

export default defineComponent
	props:
		args:
			type: String
			required: true
		options:
			###*
			# @type {() => {
			# 	name: string
			#	default: boolean
			# }[]}
			###
			type: Array
			default: => []
		action:
			# TODO: somehow impossible to get both validation and type support with coffee JSDoc
			# (no casting possible), no matter how. Runtime validation is more important
			type: Function
			default: git
		hide_result:
			type: Boolean
			default: false
	emits: [ 'success' ]
	setup: (props, { emit }) ->
		options = reactive props.options.map (option) => {
			...option
			value: option.default
		}
		options_cli = computed =>
			options
				.map ({ name, value }) =>
					if value
						name
					else ''
				.join(' ')
		constructed_command = computed =>
			(props.args + " " + options_cli.value).trim()
		default_command = constructed_command.value
		command = ref ''
		reset_command = =>
			command.value = constructed_command.value
		watchEffect reset_command
		text_changed = computed =>
			command.value != constructed_command.value
		changed = computed =>
			command.value != default_command
		
		data = ref ''
		error = ref ''
		execute = =>
			error.value = ''
			try
				result = await props.action command.value
				if not props.hide_result
					data.value = result
				emit 'success', result
			catch e
				console.warn e
				if not e.killed and e.code == 1 and e.cmd.includes("cherry-pick") and e.stdout.includes("CONFLICT") and e.stderr.includes("after resolving the conflicts")
					error.value = "Merge conflict. You can now close this window and resolve the conflicts manually.\n\n\n" + e.stdout
				else if e.stdout
					error.value = (JSON.stringify e, null, 4).replaceAll('\\n', '\n')
				else
					error.value = e.stderr.replaceAll('\\n', '\n')


		{
			command
			options
			reset_command
			changed
			text_changed
			execute
			error
			data
		}
