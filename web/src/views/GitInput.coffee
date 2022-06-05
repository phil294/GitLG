import { git, get_state, set_state } from '../bridge.coffee'
import { ref, Ref, computed, defineComponent, reactive, watchEffect, nextTick } from 'vue'

``###*
# @typedef {{
#	value: string
#	default_active: boolean
#	active?: boolean
# }} GitOption
#
# @typedef {{
#	title: string
#	description?: string
#	immediate?: boolean
#	ignore_errors:? boolean
#	args: string
#	params?: string[]
#	options?: GitOption[]
# }} ConfigGitAction
#
# @typedef {ConfigGitAction & {
#	config_key: string
# }} GitAction
###

###*
# @param actions {ConfigGitAction[]}
# @param param_replacements {[string,string][]}
# @return {GitAction[]}
###
export parse_config_actions = (actions, param_replacements = []) =>
	namespace = param_replacements.map(([k]) => k).join('-') or 'global'
	actions.map (action) => {
		...action
		config_key: "action-#{namespace}-#{action.title}"
		params: action.params?.map (param) =>
			for replacement from param_replacements
				param = param.replaceAll(replacement[0], replacement[1])
			param
	}

export default defineComponent
	props:
		git_action:
			###* @type {() => GitAction} ###
			type: Object
			required: true
		action:
			# somehow impossible to get both validation and type support with coffee JSDoc
			# (no casting possible), no matter how. Runtime validation is more important
			type: Function
			default: git
		hide_result:
			type: Boolean
			default: false
	emits: [ 'success' ]
	###*
	# To summarize all logic below: There are `options` (checkboxes) and `command` (txt input),
	# both editable, the former modifying the latter but being locked when the latter is changed by hand.
	# `saved_config` stores a snapshot of both.
	# `params` is never saved and user-edited only.
	###
	setup: (props, { emit }) ->
		###* @type {GitOption[]} ###
		options = reactive (props.git_action.options or []).map (option) => {
			...option
			active: option.default_active
		}
		params = reactive (props.git_action.params or [])
		to_cli = (###* @type {GitOption[]} ### options = []) =>
			(props.git_action.args + " " + options.map ({ value, active }) =>
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
		config_key = "git input config " + props.git_action.config_key
		get_saved = =>
			saved_config.value = (await get_state config_key) or null
			if saved_config.value
				Object.assign options, saved_config.value.options.filter (o) =>
					# to not mess things up when changes in default options
					options.some (oo) => oo.value == o.value
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
				if params.some (p) => p.includes("'")
					throw "Params cannot contain single quotes."
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
			if props.git_action.immediate
				await execute()
				if props.git_action.ignore_errors
					emit 'success'

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
