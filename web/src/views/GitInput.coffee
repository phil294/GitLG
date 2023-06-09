import { git } from '../bridge.coffee'
import { stateful_computed } from './store.coffee'
import { ref, computed, defineComponent, reactive, watchEffect, nextTick, onMounted } from 'vue'

``###*
# @typedef {import('./types').GitOption} GitOption
# @typedef {import('./types').ConfigGitAction} ConfigGitAction
# @typedef {import('./types').GitAction} GitAction
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###
###* @template T @typedef {import('vue').ComputedRef<T>} ComputedRef ###

``###*
# @param actions {ConfigGitAction[]}
# @param replacements {[string,string][]}
# @return {GitAction[]}
###
export parse_config_actions = (actions, replacements = []) =>
	namespace = replacements.map(([k]) => k).join('-') or 'global'
	do_replacements = (###* @type {string} ### txt) =>
		for replacement from replacements
			txt = txt.replaceAll(replacement[0], replacement[1])
		txt
	actions.map (action) => {
		...action
		title: do_replacements(action.title)
		description: if action.description then do_replacements(action.description) else undefined
		config_key: "action-#{namespace}-#{action.title}"
		params: action.params?.map do_replacements
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
		hide_result:
			type: Boolean
			default: false
	emits: [ 'executed', 'success' ]
	###*
	# To summarize all logic below: There are `options` (checkboxes) and `command` (txt input),
	# both editable, the former modifying the latter but being locked when the latter is changed by hand.
	# `config` stores a snapshot of both.
	# `params` is never saved and user-edited only.
	###
	setup: (props, { emit }) ->
		# typing doesn't work https://github.com/vuejs/composition-api/issues/402
		### @type {Ref<InstanceType<import('../components/PromiseForm.vue')>|null>} ###
		# so we need the ts-ignore below. TODO
		ref_form = ref null
		onMounted =>
			if props.git_action.immediate
				# @ts-ignore
				await ref_form.value?.request_submit()
			if params_input_refs.value.length
				params_input_refs.value[0].focus()
			else
				command_input_ref.value?.focus()

		``###* @type {GitOption[]} ###
		options = reactive (props.git_action.options or []).map (option) => {
			...option
			active: option.default_active
		}
		params = reactive [...(props.git_action.params or [])]
		to_cli = (###* @type {GitOption[]} ### options = []) =>
			(props.git_action.args + " " + options.map ({ value, active }) =>
				if active
					value
				else ''
			.join(' ')).trim()
		constructed_command = computed =>
			to_cli options
		command = ref ''
		config_key = "git input config " + props.git_action.config_key
		
		``###* @type {{ options: GitOption[], command: string } | null} ###
		default_config = { options: [], command: '' }

		config = await stateful_computed(config_key, default_config)

		is_saved = computed =>
			!! config.value.command
		has_unsaved_changes = computed =>
			config.value.command != command.value
		watchEffect =>
			if config.value.command
				for option from options
					saved = config.value.options.find (o) =>
						o.value == option.value
					if saved
						option.active = saved.active
				# because modifying `options` this will have changed `command`
				# via watchEffect, we need to wait before overwriting it
				await nextTick()
				command.value = config.value.command
		save = =>
			new_saved =
				options: options
				command: command.value
			config.value = JSON.parse(### because proxy fails postMessage ### JSON.stringify(new_saved))
		reset_command = =>
			command.value = constructed_command.value
		watchEffect reset_command
		text_changed = computed =>
			command.value != constructed_command.value

		``###* @type {Ref<HTMLInputElement[]>} ###
		params_input_refs = ref []
		``###* @type {Ref<HTMLInputElement|null>} ###
		command_input_ref = ref null

		data = ref ''
		error = ref ''
		execute = =>
			error.value = ''
			if params.some (p) => p.includes("'")
				throw "Params cannot contain single quotes."
			cmd = command.value
			i = 0
			while (pos = cmd.indexOf('$'+ ++i)) > -1
				cmd = cmd.slice(0, pos) + params[i-1] + cmd.slice(pos + 2)
			try
				result = await (props.action || git) cmd
			catch e
				if not e.killed and e.code == 1 and e.stdout.includes("CONFLICT")
					error.value = "Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n\n" + e.stdout + "\n\n" + e.stderr
				else if e.stdout
					error.value = (JSON.stringify e, null, 4).replaceAll('\\n', '\n')
				else if e.stderr
					error.value = e.stderr.replaceAll('\\n', '\n')
				else
					error.value = e
				if props.action
					throw e
				else
					console.warn e
				if props.git_action.ignore_errors
					emit 'success'
				return
			finally
				emit 'executed'
			if not props.hide_result
				data.value = result
			emit 'success', result
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
			params_input_refs
			command_input_ref
			ref_form
		}
