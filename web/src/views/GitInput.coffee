import { git } from '../bridge.coffee'
import { stateful_computed, push_history } from './store.coffee'
import { ref, computed, defineComponent, reactive, watchEffect, nextTick, onMounted } from 'vue'

###*
# @typedef {import('./types').GitOption} GitOption
# @typedef {import('./types').ConfigGitAction} ConfigGitAction
# @typedef {import('./types').GitAction} GitAction
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###
###* @template T @typedef {import('vue').ComputedRef<T>} ComputedRef ###
###* @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef ###

###*
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
		###* @type {GitOption[]} ###
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
		if props.git_action.config_key
			config_key = "git input config " + props.git_action.config_key
		###* @type {{ options: GitOption[], command: string } | null} ###
		default_config = { options: [], command: '' }
		###* @type {WritableComputedRef<typeof default_config>} ###
		config = null
		config_load_promise = new Promise (loaded) =>
			if config_key
				config = stateful_computed(config_key, default_config, loaded)
			else
				loaded(null)
		is_saved = computed =>
			!! config?.value?.command
		has_unsaved_changes = computed =>
			config?.value?.command != command.value
		watchEffect =>
			if is_saved.value
				for option from options
					saved = config?.value.options.find (o) =>
						o.value == option.value
					if saved
						option.active = saved.active
				# because modifying `options` this will have changed `command`
				# via watchEffect, we need to wait before overwriting it
				await nextTick()
				command.value = config?.value.command
		save = =>
			new_saved =
				options: options
				command: command.value
			config?.value = JSON.parse(### because proxy fails postMessage ### JSON.stringify(new_saved))
		reset_command = =>
			command.value = constructed_command.value
		watchEffect reset_command
		text_changed = computed =>
			command.value != constructed_command.value

		###* @type {Ref<HTMLInputElement[]>} ###
		params_input_refs = ref []
		###* @type {Ref<HTMLInputElement|null>} ###
		command_input_ref = ref null
		onMounted =>
			if params_input_refs.value.length
				params_input_refs.value[0].focus()
			else
				command_input_ref.value?.focus()

		data = ref ''
		error = ref ''
		###* @param args {{before_execute?: ((cmd: string) => string) | undefined}} ###
		execute = ({ before_execute } = {}) =>
			error.value = ''
			if params.some (p) => p.includes('"') or p.includes('\\')
				throw "Params cannot contain quotes or backslashes."
			cmd = command.value
			i = 0
			while (pos = cmd.indexOf('$'+ ++i)) > -1
				cmd = cmd.slice(0, pos) + params[i-1] + cmd.slice(pos + 2)
			if before_execute
				cmd = before_execute(cmd)
			try
				result = await (props.action || git) cmd
			catch e
				e = e.message_error_response || e.message || e
				if e.includes("CONFLICT")
					error.value = "Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n" + e
				else
					if text_changed.value
						error.value = "git command failed. Try clicking RESET and try again!\n\nError message:\n#{e}"
					else
						error.value = e
					if props.action
						throw new Error(e)
					else
						console.warn e
				if props.git_action.ignore_errors
					emit 'success'
				return
			finally
				emit 'executed'
				push_history type: 'git', value: cmd
			if not props.hide_result
				data.value = result
			emit 'success', result

		# typing doesn't work https://github.com/vuejs/composition-api/issues/402
		### @type {Ref<InstanceType<import('../components/PromiseForm.vue')>|null>} ###
		# so we need the ts-ignore below. TODO
		ref_form = ref null
		onMounted =>
			await config_load_promise
			await nextTick()
			if props.git_action.immediate
				# @ts-ignore
				await ref_form.value?.request_submit()

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
