import { git } from '../bridge.js'
import { stateful_computed, push_history } from './store.js'
import { ref, computed, defineComponent, reactive, watchEffect, nextTick, onMounted } from 'vue'

/**
 * @typedef {import('./types').GitOption} GitOption
 * @typedef {import('./types').ConfigGitAction} ConfigGitAction
 * @typedef {import('./types').GitAction} GitAction
 */
/** @template T @typedef {import('vue').Ref<T>} Ref */
/** @template T @typedef {import('vue').ComputedRef<T>} ComputedRef */
/** @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef */

/**
 * @param actions {ConfigGitAction[]}
 * @param replacements {[string,string][]}
 * @return {GitAction[]}
 */
export let parse_config_actions = (actions, replacements = []) => {
	let namespace = replacements.map(([k]) => k).join('-') || 'global'
	function do_replacements(/** @type {string} */ txt) {
		let replacement
		for (replacement of replacements)
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
			/** @type {() => GitAction} */
			type: Object,
			required: true,
		},
		action: {
			// somehow impossible to get both validation and type support with coffee JSDoc
			// (no casting possible), no matter how. Runtime validation is more important < TODO
			type: Function,
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
		let ref_form
		/** @type {GitOption[]} */
		let options = reactive((props.git_action.options || []).map((option) => ({
			...option,
			active: option.default_active,
		})))
		let params = reactive([...props.git_action.params || []])
		function to_cli(/** @type {GitOption[]} */ options = []) {
			return (props.git_action.args + ' ' + options.map(({ value, active }) =>
				active ? value : ''
			).join(' ')).trim()
		}
		let constructed_command = computed(() =>
			to_cli(options))
		let command = ref('')
		if (props.git_action.config_key) {
			let config_key = 'git input config ' + props.git_action.config_key
		}
		/** @type {{ options: GitOption[], command: string } | null} */
		let default_config = { options: [], command: '' }
		/** @type {WritableComputedRef<typeof default_config>} */
		let config = null
		let config_load_promise = new Promise((loaded) => {
			if (config_key)
				config = stateful_computed(config_key, default_config, loaded)
			else
				loaded(null)
		})
		let is_saved = computed(() => !! config?.value?.command)
		let has_unsaved_changes = computed(() =>
			config?.value?.command !== command.value)
		watchEffect(async () => {
			let option
			if (is_saved.value) {
				for (option of options) {
					let saved = config?.value.options.find((o) =>
						o.value === option.value)
					if (saved)
						option.active = saved.active
				}
				// because modifying `options` this will have changed `command`
				// via watchEffect, we need to wait before overwriting it
				await nextTick()
				command.value = config?.value.command
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

		/** @type {Ref<HTMLInputElement[]>} */
		let params_input_refs = ref([])
		/** @type {Ref<HTMLInputElement|null>} */
		let command_input_ref = ref(null)
		onMounted(() => {
			if (params_input_refs.value.length)
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
			for (let i = 1; i <= _params.length; i++) {
				while ((pos = cmd.indexOf('$' + i)) > -1)
					cmd = cmd.slice(0, pos) + _params[i - 1] + cmd.slice(pos + 2)
			if (before_execute)
				cmd = before_execute(cmd)
			let result
			try {
				result = await (props.action || git)(cmd)
			} catch (e) {
				e = e.message_error_response || e.message || e
				if (e.includes?.('CONFLICT'))
					error.value = 'Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n' + e
				else {
					if (text_changed.value)
						error.value = `git command failed. Try clicking RESET and try again!\n\nError message:\n${e}`
					else
						error.value = e
					if (props.action)
						throw new Error(e)
					else
						console.warn(e)
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

		// typing doesn't work https://github.com/vuejs/composition-api/issues/402
		/* @type {Ref<InstanceType<import('../components/PromiseForm.vue')>|null>} */
		// so we need the ts-ignore below. TODO
		ref_form = ref(null)
		onMounted(async () => {
			await config_load_promise
			await nextTick()
			if (props.git_action.immediate)
				// @ts-ignore
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
			ref_form
		}
	},
})
