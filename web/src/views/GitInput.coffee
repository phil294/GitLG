import { git, get_state, set_state } from '../store.coffee'
import { ref, Ref, computed, defineComponent, reactive, watchEffect, nextTick } from 'vue'

``###* @typedef {{
# 	value: string
#	default_active: boolean
#	active?: boolean
# }} GitOption ###

export default defineComponent
	props:
		args:
			type: String
			required: true
		options:
			###* @type {() => GitOption[]} ###
			type: Array
			default: => []
		params:
			###* @type {() => string[]} ###
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
		immediate:
			type: Boolean
			default: false
		config_key:
			type: String
			required: true
	emits: [ 'success' ]
	###*
	# To summarize all logic below: There are `options` (checkboxes) and `command` (txt input),
	# both editable, the former modifying the latter but being locked when the latter is changed by hand.
	# `saved_config` stores a snapshot of both.
	# `params` is never saved and user-edited only.
	###
	setup: (props, { emit }) ->
		###* @type {GitOption[]} ###
		options = reactive props.options.map (option) => {
			...option
			active: option.default_active
		}
		params = reactive props.params
		to_cli = (###* @type {GitOption[]} ### options = []) =>
			(props.args + " " + options.map ({ value, active }) =>
				if active
					value
				else ''
			.join(' ')).trim()
		constructed_command = computed =>
			to_cli options
		command = ref ''
		``###* @type {Ref<{ options: GitOption[], command: string } | null>} ###
		saved_config = ref null
		is_saved = computed =>
			!! saved_config.value?.command
		has_unsaved_changes = computed =>
			saved_config.value?.command != command.value
		config_key = "git input config " + props.config_key
		get_saved = =>
			saved_config.value = (await get_state config_key) or null
			if saved_config.value
				Object.assign options, saved_config.value.options
				# because modifying `options` this will have changed `command`
				# via watchEffect, we need to wait before overwriting it
				await nextTick()
				command.value = saved_config.value.command
		save = =>
			new_saved =
				options: options
				command: command.value
			await set_state config_key, JSON.parse(### because proxy fails postMessage ### JSON.stringify(new_saved))
			saved_config.value = new_saved
		reset_command = =>
			command.value = constructed_command.value
		watchEffect reset_command
		text_changed = computed =>
			command.value != constructed_command.value

		data = ref ''
		error = ref ''
		execute = =>
			error.value = ''
			try
				cmd = command.value
				i = 0
				while (pos = cmd.indexOf('$'+ ++i)) > -1
					cmd = cmd.slice(0, pos) + params[i-1] + cmd.slice(pos + 2)
				result = await props.action cmd
				if not props.hide_result
					data.value = result
				emit 'success', result
			catch e
				console.warn e
				if not e.killed and e.code == 1 and e.stdout.includes("CONFLICT") and e.stderr.includes("after resolving the conflicts")
					error.value = "Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n\n" + e.stdout
				else if e.stdout
					error.value = (JSON.stringify e, null, 4).replaceAll('\\n', '\n')
				else if e.stderr
					error.value = e.stderr.replaceAll('\\n', '\n')
				else
					error.value = e

		do =>
			await get_saved()
			if props.immediate
				execute()

		{
			command
			options
			params
			reset_command
			text_changed
			execute
			error
			data
			is_saved
			has_unsaved_changes
			save
		}
