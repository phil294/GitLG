<template lang="slm">
form @submit.prevent="submit" enctype="multipart/form-data"
	/ using an invisible fieldset wrapper to group disable attribute for all children (does not work on <form> directly)
	fieldset.low-key :disabled="disabled || loading" :class="$attrs.class"
		legend
			slot name="legend"
		slot
	slot name="loading"
		p v-if="loading"
			| Loading...
</template>

<script lang="coffee">
export default
	props:
		###*
		# The callback for a successful form submit. If it returns a Promise,
		# it will be visually awaited before the form gets editable again.
		# @type {({
		# 	form_data: FormData,
		# 	event: Event,
		# 	values: { [form_key: string]: any },
		# 	array_values: { [form_key: string]: any[] },
		# 	[form_key: string]: any
		# }) => any}
		###
		action:
			type: Function
			required: true
		onetime:
			type: Boolean
			default: false
		disabled:
			type: Boolean
			default: false
	emits: [ 'submit', 'success' ]
	data: =>
		loading: false
	methods:
		submit: (event) ->
			@loading = true
			@$emit 'submit', event

			form_data = new FormData event.target
			
			values = {}
			# There can be multiple values for the same form data key, e.g.
			# <input type=file multiple>
			array_values = {}
			for form_key from [...form_data.keys()]
				form_values = form_data.getAll form_key
				values[form_key] = form_values[0]
				array_values[form_key] = form_values

			try
				await Promise.all [
					@action {
						...values,
						form_data, values, array_values, event,
					}
				,
					# force delay when the network response is quick, because overly fast button responses are confusing
					new Promise (ok) => setTimeout ok, 150
				]
				@$emit 'success'
			catch e
				throw e
			finally
				if not @onetime
					@loading = false
</script>

<style lang="stylus" scoped>
fieldset.low-key
	margin 0
	padding 0
	border none
</style>
