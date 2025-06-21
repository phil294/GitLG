<template>
	<div class="git-input col gap-10">
		<promise-form ref="ref_form" :action="execute" class="col gap-5" :disabled="!params">
			<div class="row align-center gap-10">
				<code>git</code>
				<input ref="command_input_ref" v-model="command" class="command flex-1">
			</div>
			<div class="input-controls justify-flex-end align-center gap-10">
				<div v-if="text_changed" class="warn">
					<details>
						<summary class="center">
							Edited. Be careful!
						</summary>
						Editing this field can be dangerous, as it is executed without escaping. If you do not know what you are doing, please click Reset.
					</details>
				</div>
				<button v-if="text_changed" class="reset btn btn-2 gap-3" type="button" @click="reset_command()">
					<i class="codicon codicon-discard" />
					Reset
				</button>
				<div v-if="is_saved && ! has_unsaved_changes" class="saved">
					Saved
				</div>
				<button v-if="has_unsaved_changes" class="save btn btn-2 gap-3" type="button" @click="save()">
					<i class="codicon codicon-save" />
					Save
				</button>
			</div>
			<div v-for="(param, i) in params" :key="i" class="param">
				<label class="row align-center gap-5">
					Param ${{ i+1 }}
					<Component :is="param.multiline ? 'textarea' : 'input'" ref="params_input_refs" :value="params_model[i]" :placeholder="param.placeholder" :readonly="param.readonly" class="flex-1" required rows="4" onfocus="select()" @input="params_model[i] = $event.target.value" /></label>
			</div>
			<div class="execute">
				<button class="btn gap-3">
					<i class="codicon codicon-check" />
					Execute
				</button>
			</div>
		</promise-form>
		<div v-if="result_error" class="error-response padding-l">
			{{ result_error }}
		</div>
		<div v-if="result_data" class="success-response padding-l">
			Successful result:<br>{{ result_data }}
		</div>
		<div v-if="options.length" class="options">
			<div>
				Common options
			</div>
			<ul>
				<li v-for="option of options" :key="option.value" :class="{changed: option.active !== option.default_active}" class="option row gap-10">
					<label class="row align-center">
						<input v-model="option.active" :disabled="text_changed" type="checkbox">
						{{ option.value }}
					</label>
					<details v-if="option.info">
						<summary>
							{{ option.info }}
						</summary>
						{{ option.info }}
					</details>
				</li>
			</ul>
		</div>
	</div>
</template>

<script setup>
/*
 * To summarize all logic below: There are `options` (checkboxes) and `command` (txt input),
 * both editable, the former modifying the latter but being locked when the latter is changed by hand.
 * `stored` holds a snapshot of both.
 * `params` is never saved and user-edited only.
 */
import { git } from '../bridge.js'
import { push_history } from '../data/store/history'
import state from '../data/state.js'
import { ref, computed, reactive, watchEffect, nextTick, onMounted, useTemplateRef } from 'vue'

let props = defineProps({
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
})
let emit = defineEmits(['executed', 'success'])

/** @type {GitOption[]} */
let options = reactive((props.git_action.options || []).map((option) => ({
	...option,
	active: option.default_active,
})))
/** @type {Vue.Ref<string[]>} */
let params_model = ref([])
/** @type {Vue.Ref<GitActionParam[] | null>} */
let params = ref(null)
let load_params_promise = props.git_action.params()
	.then(loaded => {
		params.value = loaded
		params_model.value = params.value.map(p => p.value)
	})
function compute_command(/** @type {GitOption[]} */ opts = []) {
	return (props.git_action.args + ' ' + opts.map(({ value, active }) =>
		active ? value : '',
	).join(' ')).trim()
}
let computed_command = computed(() =>
	compute_command(options))
let command = ref('')
let storage_key = null
if (props.git_action.storage_key)
	storage_key = 'git input config ' + props.git_action.storage_key

/** @type {{ options: GitOption[], command: string } | null} */
let default_stored = { options: [], command: '' }
/** @type {Vue.WritableComputedRef<typeof default_stored>|null} */
let stored = null // TODO: assign stateful computed direcgtly here, why the async init?
let load_stored_promise = new /** @type {typeof Promise<void>} */(Promise)((loaded) => {
	if (storage_key)
		stored = state(storage_key, default_stored, loaded).ref
	else
		loaded()
})
let is_saved = computed(() => !! stored?.value?.command)
let has_unsaved_changes = computed(() =>
	stored?.value?.command !== command.value)
watchEffect(async () => {
	if (is_saved.value) {
		for (let option of options) {
			let saved = stored?.value.options.find((o) =>
				o.value === option.value)
			if (saved)
				option.active = saved.active
		}
		// because modifying `options` this will have changed `command`
		// via watchEffect, we need to wait before overwriting it
		// TODO: ^ instead, maybe just set command if text_changed.value
		await nextTick()
		command.value = stored?.value.command || ''
	}
})
function save() {
	let new_saved = {
		options,
		command: command.value,
	}
	if (stored)
		stored.value = JSON.parse(/* because proxy fails postMessage */JSON.stringify(new_saved))
}
function reset_command() {
	command.value = computed_command.value
}
watchEffect(reset_command)
let text_changed = computed(() =>
	command.value !== computed_command.value)

let params_input_refs = /** @type {Readonly<Vue.ShallowRef<Array<HTMLInputElement>>>} */ (useTemplateRef('params_input_refs'))
let command_input_ref = /** @type {Readonly<Vue.ShallowRef<HTMLInputElement|null>>} */ (useTemplateRef('command_input_ref'))
onMounted(async () => {
	await load_params_promise
	await nextTick()
	let writable_param_index = params.value?.findIndex(p => ! p.readonly) ?? -1
	if (writable_param_index > -1)
		params_input_refs.value[writable_param_index]?.focus()
	else
		command_input_ref.value?.focus()
	;[...(params_input_refs.value || []),
		command_input_ref.value]
		// FIXME: outdated
		.map(r => r?.shadowRoot?.querySelector('input'))
		.filter(is_truthy)
		.forEach(input => {
			input.style.fontFamily = 'var(--vscode-editor-font-family, monospace)'
			input.style.fontSize = 'small'
		})
})

let result_data = ref('')
let result_error = ref('')
/** @param args {{before_execute?: ((cmd: string) => string) | undefined, fetch_stash_refs?: boolean, fetch_branches?: boolean}} */
async function execute({ before_execute, fetch_stash_refs, fetch_branches } = {}) {
	await load_stored_promise
	await load_params_promise
	await nextTick()
	result_error.value = ''
	let _params = params_model.value.map((p) => p.replaceAll('\\n', '\n'))
	if (_params.some((p) => p.match(/"|(\\([^n]|$))/)))
		// FIXME: subject with quotes
		return result_error.value = 'Params cannot contain quotes or backslashes.'
	let cmd = command.value
	let pos = null
	for (let i = 1; i <= _params.length; i++)
		while ((pos = cmd.indexOf('$' + i)) > -1)
			cmd = cmd.slice(0, pos) + _params[i - 1] + cmd.slice(pos + 2)
	if (before_execute)
		cmd = before_execute(cmd)
	let result = null
	try {
		result = await (props.action || git)(cmd, { fetch_stash_refs, fetch_branches })
	} catch (action_error) {
		let action_error_msg = action_error.message_error_response || action_error.message || action_error
		if (action_error_msg.includes?.('CONFLICT'))
			result_error.value = 'Command finished with CONFLICT. You can now close this window and resolve the conflicts manually.\n\n' + action_error_msg
		else {
			if (text_changed.value)
				result_error.value = `git command failed. Try clicking RESET and try again!\n\nError message:\n${action_error_msg}`
			else
				result_error.value = action_error_msg
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
		result_data.value = result
	emit('success', result)
}

let ref_form = useTemplateRef('ref_form')
onMounted(async () => {
	if (props.git_action.immediate)
		await ref_form.value?.request_submit()
})

defineExpose({
	execute,
})
</script>
<style>
.options .option.changed {
	border-left: 2px solid #bc9550;
	margin-left: -6px;
	padding-left: 4px;
}
.options .option label {
	white-space: pre;
	flex-grow: 1;
	flex-shrink: 1;
	flex-basis: 0%;
	min-width: auto;
}
.options .option details {
	white-space: pre-line;
	flex: 2;
}
.options .option details > summary {
	overflow: hidden;
	text-overflow: ellipsis;
	color: var(--text-secondary);
}
.error-response,
.success-response {
	white-space: pre-wrap;
}
.param {
	white-space: pre;
}
.error-response {
	color: #e53c3c;
}
textarea {
	border: 1px solid var(--vscode-settings-textInputBorder, var(--vscode-settings-textInputBackground));
	border-radius: 2px;
}
</style>
