<template lang="slm">
div.col.gap-10
	promise-form :action="execute"
		.row.align-center.gap-10
			code git 
			input.command v-model="command"
		button.btn
			| ✓ Execute
	.align-center v-if="text_changed"
		button.btn.btn-2 @click="reset_command()"
			| ↺ Reset
	.error-response.padding-l v-if="error"
		| Command failed: 
		| {{ error }}
	.success-response.padding-l v-if="data"
		| Successful result:<br>
		| {{ data }}
	div v-if="options.length"
		div Common options
		div v-if="text_changed"
			| You have edited the text input by hand. Options toggling is disabled. Reset if desired.
		ul.options
			li v-for="option of options" :class="{changed: option.value !== option.default}"
				label.row.align-center.gap-5
					input type="checkbox" v-model="option.value" :disabled="text_changed"
					| {{ option.name }}
</template>

<script lang="coffee" src="./GitInput.coffee"></script>

<style lang="stylus">
.options
	.changed
		border-left 2px solid #bc9550 // like vscode settings ui
.error-response, .success-response
	white-space pre-wrap
.error-response
	color #e53c3c
</style>