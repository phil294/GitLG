<template>
	<form ref="form_ref" enctype="multipart/form-data" @submit.prevent="submit">
		<!-- using an invisible fieldset wrapper to group disable attribute for all children (does not work on <form> directly) -->
		<fieldset :class="$attrs.class" :disabled="disabled || loading" class="low-key">
			<legend>
				<slot name="legend" />
			</legend>
			<slot />
		</fieldset>
		<slot name="loading">
			<p v-if="loading">
				Loading...
			</p>
		</slot>
	</form>
</template>
<script>
export default {
	props: {
		/**
		 * The callback for a successful form submit. If it returns a Promise,
		 * it will be visually awaited before the form gets editable again.
		 * @type {({
		 * 	form_data: FormData,
		 * 	event: Event,
		 * 	values: { [form_key: string]: any },
		 * 	array_values: { [form_key: string]: any[] },
		 * 	[form_key: string]: any
		 * }) => any}
		 */
		action: { type: Function, required: true },
		onetime: { type: Boolean, default: false },
		disabled: { type: Boolean, default: false },
	},
	emits: ['submit', 'success'],
	data: () => ({
		loading: false,
	}),
	methods: {
		request_submit() {
			this.$refs.form_ref.requestSubmit()
		},
		async submit(event) {
			if (! event)
				throw new Error('Cannot call `submit` on PromiseForm directly. Use `request_submit` instead.')
			this.loading = true
			this.$emit('submit', event)

			let form_data = new FormData(event.target)

			let values = {}
			// There can be multiple values for the same form data key, e.g.
			// <input type=file multiple>
			let array_values = {}
			for (let form_key of [...form_data.keys()]) {
				let form_values = form_data.getAll(form_key)
				values[form_key] = form_values[0]
				array_values[form_key] = form_values
			}
			try {
				await Promise.all([
					this.action({
						...values,
						form_data,
						values,
						array_values,
						event,
					}),
					// force delay when the network response is quick, because overly fast button responses are confusing
					// FIXME: main log delayed by this
					new Promise((ok) => setTimeout(ok, 150)),
				])
				this.$emit('success')
			} catch (e) {
				if (! (e instanceof Error))
					// eslint-disable-next-line no-ex-assign
					e = new Error(e)
				e.domChain = []
				let p = this.$el
				while (p) {
					e.domChain.push(`${p.tagName.toLowerCase()}.${p.className}#${p.id}`)
					p = p.parentElement
				}
				throw e
			} finally {
				if (! this.onetime)
					this.loading = false
			}
		},
	},
}
</script>
<style scoped>
fieldset.low-key {
	margin: 0;
	padding: 0;
	border: none;
}
</style>
