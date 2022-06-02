import { git, get_config, set_config } from '../store.coffee'
import { ref, Ref, computed, defineComponent, reactive, watchEffect, nextTick } from 'vue'

``###* @typedef {{
# 	name: string
#	default: boolean
#	value?: boolean
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
		title:
			# also serves as a config key
			type: String
			required: true
	emits: [ 'success' ]
	###*
	# To summarize all logic below: There are `options` (checkboxes) and `command` (txt input),
	# both editable, the former modifying the latter but being locked when the latter is changed by hand.
	# `saved_config` stores a snapshot of both.
	###
	setup: (props, { emit }) ->
		###* @type {GitOption[]} ###
		options = reactive props.options.map (option) => {
			...option
			value: option.default
		}
		to_cli = (###* @type {GitOption[]} ### options = []) =>
			(props.args + " " + options.map ({ name, value }) =>
				if value
					name
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
		config_key = "git input config " + props.title
		get_saved = =>
			saved_config.value = (await get_config config_key) or null
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
			await set_config config_key, JSON.parse(### because proxy fails postMessage ### JSON.stringify(new_saved))
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
				result = await props.action command.value
				if not props.hide_result
					data.value = result
				emit 'success', result
			catch e
				console.warn e
				if not e.killed and e.code == 1 and e.stdout.includes("CONFLICT") and e.stderr.includes("after resolving the conflicts")
					error.value = "Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n\n" + e.stdout
				else if e.stdout
					error.value = (JSON.stringify e, null, 4).replaceAll('\\n', '\n')
				else
					error.value = e.stderr.replaceAll('\\n', '\n')

		do =>
			await get_saved()
			if props.immediate
				execute()

		{
			command
			options
			reset_command
			text_changed
			execute
			error
			data
			is_saved
			has_unsaved_changes
			save
		}
