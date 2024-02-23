<template lang="slm">
.git-input.col.gap-10
	promise-form.col.gap-5 :action="execute" ref="ref_form"
		.row.align-center.gap-10
			code git
			input.command.flex-1 v-model="command" ref="command_input_ref"
		.input-controls.justify-flex-end.align-center.gap-10
			div.warn v-if="text_changed"
				details
					summary.center Edited. Be careful!
					| Editing this field can be dangerous, as it is executed without escaping. If you do not know what you are doing, please click Reset.
			button.reset.btn.btn-2.gap-3 type="button" v-if="text_changed" @click="reset_command()"
				i.codicon.codicon-discard
				| Reset
			.saved v-if="is_saved && ! has_unsaved_changes"
				| Saved
			button.save.btn.btn-2.gap-3 type="button" v-if="has_unsaved_changes" @click="save()"
				i.codicon.codicon-save
				| Save
		.param v-for="(param, i) in params"
			label.row.align-center.gap-5
				| Param \${{ i+1 }}
				input.flex-1 v-model="params[i]" onfocus="select()" ref="params_input_refs"
		.execute
			button.btn.gap-3
				i.codicon.codicon-check
				| Execute
	.error-response.padding-l v-if="error"
		| {{ error }}
	.success-response.padding-l v-if="data"
		| Successful result:<br>
		| {{ data }}
	.options v-if="options.length"
		div Common options
		ul
			li.option.row.gap-10 v-for="option of options" :class="{changed: option.active !== option.default_active}"
				label.row.align-center.flex-1
					input type="checkbox" v-model="option.active" :disabled="text_changed"
					| {{ option.value }}
				details.flex-1 v-if="option.info"
					summary {{ option.info }}
					| {{ option.info }}
</template>

<script lang="coffee" src="./GitInput.coffee"></script>

<style lang="stylus">
.options
	.option
		&.changed
			border-left 2px solid #bc9550 // like vscode settings ui
		label
			white-space pre
			display contents
		details
			white-space pre-line
			> summary
				overflow hidden
				text-overflow ellipsis
				color grey
.error-response, .success-response
	white-space pre-wrap
.param
	white-space pre
.error-response
	color #e53c3c
</style>