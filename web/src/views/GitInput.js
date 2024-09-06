import { git } from '../bridge.js'
import { stateful_computed, push_history } from './store.js'
import { ref, computed, defineComponent, reactive, watchEffect, nextTick, onMounted, useTemplateRef } from 'vue'

/**
 * @param actions {ConfigGitAction[]}
 * @param replacements {[string,string][]}
 * @returns {GitAction[]}
 */
export let parse_config_actions = (actions, replacements = []) => {
	let namespace = replacements.map(([k]) => k).join('-') || 'global'
	function do_replacements(/** @type {string} */ txt) {
		for (let replacement of replacements)
			txt = txt.replaceAll(replacement[0], replacement[1])
		return txt
	}
	return actions.map((action) => ({
		...action,
		title: do_replacements(action.title),
		description: action.description ? do_replacements(action.description) : undefined,
		config_key: `action-${namespace}-${action.title}`,
		params: action.params?.map(do_replacements),
	}))
}

export default defineComponent({
	props: {
		git_action: {
			/** @type {Vue.PropType<GitAction>} */
			type: Object,
			required: true,
		},
		action: {
			type: Function,
			default: null,
		},
		hide_result: { type: Boolean, default: false },
	},
	emits: ['executed', 'success'],
	/**
	 * To summarize all logic below: There are `options` (checkboxes) and `command` (txt input),
	 * both editable, the former modifying the latter but being locked when the latter is changed by hand.
	 * `config` stores a snapshot of both.
	 * `params` is never saved and user-edited only.
	 */
	setup(props, { emit }) {
		/** @type {GitOption[]} */
		let options = reactive((props.git_action.options || []).map((option) => ({
			...option,
			active: option.default_active,
		})))
		let params = reactive([...props.git_action.params || []])
		function to_cli(/** @type {GitOption[]} */ opts = []) {
			return (props.git_action.args + ' ' + opts.map(({ value, active }) =>
				active ? value : '',
			).join(' ')).trim()
		}
		let constructed_command = computed(() =>
			to_cli(options))
		let command = ref('')
		let config_key = null
		if (props.git_action.config_key)
			config_key = 'git input config ' + props.git_action.config_key

		/** @type {{ options: GitOption[], command: string } | null} */
		let default_config = { options: [], command: '' }
		/** @type {Vue.WritableComputedRef<typeof default_config>|null} */
		let config = null
		let config_load_promise = new /** @type {typeof Promise<void>} */(Promise)((loaded) => { // eslint-disable-line no-extra-parens
			if (config_key)
				config = stateful_computed(config_key, default_config, loaded)
			else
				loaded()
		})
		let is_saved = computed(() => !! config?.value?.command)
		let has_unsaved_changes = computed(() =>
			config?.value?.command !== command.value)
		watchEffect(async () => {
			if (is_saved.value) {
				for (let option of options) {
					let saved = config?.value.options.find((o) =>
						o.value === option.value)
					if (saved)
						option.active = saved.active
				}
				// because modifying `options` this will have changed `command`
				// via watchEffect, we need to wait before overwriting it
				await nextTick()
				command.value = config?.value.command || ''
			}
		})
		function save() {
			let new_saved = {
				options,
				command: command.value,
			}
			if (config)
				config.value = JSON.parse(/* because proxy fails postMessage */JSON.stringify(new_saved))
		}
		function reset_command() {
			command.value = constructed_command.value
		}
		watchEffect(reset_command)
		let text_changed = computed(() =>
			command.value !== constructed_command.value)

		let params_input_refs = /** @type {Readonly<Vue.ShallowRef<Array<HTMLInputElement>>>} */ (useTemplateRef('params_input_refs')) // eslint-disable-line no-extra-parens
		let command_input_ref = /** @type {Readonly<Vue.ShallowRef<HTMLInputElement|null>>} */ (useTemplateRef('command_input_ref')) // eslint-disable-line no-extra-parens
		onMounted(() => {
			if (params_input_refs.value?.length)
				params_input_refs.value[0].focus()
			else
				command_input_ref.value?.focus()
		})

		let data = ref('')
		let error = ref('')
		/** @param args {{before_execute?: ((cmd: string) => string) | undefined}} */
		async function execute({ before_execute } = {}) {
			error.value = ''
			let _params = params.map((p) => p.replaceAll('\\n', '\n'))
			if (_params.some((p) => p.match(/"|(\\([^n]|$))/)))
				error.value = 'Params cannot contain quotes or backslashes.'
			let cmd = command.value
			let pos = null
			for (let i = 1; i <= _params.length; i++)
				while ((pos = cmd.indexOf('$' + i)) > -1)
					cmd = cmd.slice(0, pos) + _params[i - 1] + cmd.slice(pos + 2)
			if (before_execute)
				cmd = before_execute(cmd)
			let result = null
			try {
				result = await (props.action || git)(cmd)
			} catch (action_error) {
				let action_error_msg = action_error.message_error_response || action_error.message || action_error
				if (action_error_msg.includes?.('CONFLICT'))
					error.value = 'Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n' + action_error_msg
				else {
					if (text_changed.value)
						error.value = `git command failed. Try clicking RESET and try again!\n\nError message:\n${action_error_msg}`
					else
						error.value = action_error_msg
					if (props.action)
						throw action_error
					else
						console.warn(action_error)
				}
				if (props.git_action.ignore_errors)
					emit('success')
				return
			} finally {
				emit('executed')
				push_history({ type: 'git', value: cmd })
			}
			if (! props.hide_result)
				data.value = result
			emit('success', result)
		}

		let ref_form = /** @type {Readonly<Vue.ShallowRef<InstanceType<typeof import('../components/PromiseForm.vue')>|null>>} */ (useTemplateRef('ref_form')) // eslint-disable-line no-extra-parens
		onMounted(async () => {
			await config_load_promise
			await nextTick()
			if (props.git_action.immediate)
				await ref_form.value?.request_submit()
		})

		return {
			command,
			options,
			params,
			reset_command,
			text_changed,
			execute,
			error,
			data,
			is_saved,
			has_unsaved_changes,
			save,
			params_input_refs,
			command_input_ref,
			ref_form,
		}
	},
})
