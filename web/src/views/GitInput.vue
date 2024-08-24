<template>
	<div class="git-input col gap-10">
		<promise-form ref="ref_form" :action="execute" class="col gap-5">
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
			<div v-for="(param, i) in params" class="param">
				<label class="row align-center gap-5">
					Param ${{ i+1 }}
					<input ref="params_input_refs" v-model="params[i]" class="flex-1" onfocus="select()">
				</label>
			</div>
			<div class="execute">
				<button class="btn gap-3">
					<i class="codicon codicon-check" />
					Execute
				</button>
			</div>
		</promise-form>
		<div v-if="error" class="error-response padding-l">
			{{ error }}
		</div>
		<div v-if="data" class="success-response padding-l">
			Successful result:<br>{{ data }}
		</div>
		<div v-if="options.length" class="options">
			<div>
				Common options
			</div>
			<ul>
				<li v-for="option of options" :class="{changed: option.active !== option.default_active}" class="option row gap-10">
					<label class="row align-center flex-1">
						<input v-model="option.active" :disabled="text_changed" type="checkbox">
						{{ option.value }}
					</label>
					<details v-if="option.info" class="flex-1">
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
<script src="./GitInput"></script>
<style>
.options .option.changed {
	border-left: 2px solid #bc9550;
}
.options .option label {
	white-space: pre;
	display: contents;
}
.options .option details {
	white-space: pre-line;
}
.options .option details > summary {
	overflow: hidden;
	text-overflow: ellipsis;
	color: #808080;
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
</style>
