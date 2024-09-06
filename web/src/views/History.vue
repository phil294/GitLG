<template>
	<details id="history" ref="details_ref" class="center">
		<summary>
			History...
		</summary>
		<div class="dv">
			<div v-if="history_mapped.length">
				<div class="flex justify-flex-end">
					<button id="clear-history" class="btn" @click="clear_history">
						<i class="codicon codicon-trash" />
						Clear repository history
					</button>
				</div>
				<ol class="entries">
					<li v-for="(entry, entry_i) of history_mapped" :key="entry.datetime" class="flex">
						<div :title="entry.datetime" class="entry flex-1">
							<commit-row v-if="entry.type == 'commit_hash' && entry.ref" :commit="entry.ref" role="button" @click="$emit('commit_clicked', entry.ref)" />
							<div v-else-if="entry.type == 'commit_hash'">
								Commit '{{ entry.value }}' not found!
							</div>
							<git-action-button v-else-if="entry.type == 'git'" :git_action="entry.ref" />
							<button v-else-if="entry.type == 'txt_filter'" class="btn" @click="$emit('apply_txt_filter', entry.value)">
								<i class="codicon codicon-search" />
								Search: <code>{{ entry.value }}</code>
							</button>
							<div v-else>
								Unknown history entry: {{ entry.value }}
							</div>
						</div>
						<div class="delete">
							<button class="btn" title="Remove this item from the repository history" @click="remove_history_entry(entry_i)">
								<i class="codicon codicon-trash" />
							</button>
						</div>
					</li>
				</ol>
			</div>
			<p v-else>
				Repository history empty!
			</p>
		</div>
	</details>
</template>
<script>
import { computed, onMounted, onUnmounted, useTemplateRef } from 'vue'
import { history, commits } from './store.js'

export default {
	emits: ['commit_clicked', 'apply_txt_filter'],
	setup() {
		let history_mapped = computed(() =>
			(history.value || []).slice().reverse().map((entry) => {
				let ref = null
				if (entry.type === 'commit_hash')
					ref = commits.value?.find((commit) =>
						commit.hash === entry.value)
				else if (entry.type === 'git')
					ref = {
						title: 'git ' + entry.value,
						args: entry.value,
						description: 'History entry',
						icon: 'history',
					}
				return {
					// TODO obj spread..?
					type: entry.type,
					value: entry.value,
					datetime: entry.datetime,
					ref,
				}
			}))
		function clear_history() {
			history.value = []
		}
		function remove_history_entry(/** @type {number} */ entry_i) {
			history.value.splice(history.value.length - entry_i - 1, 1)
			history.value = history.value.slice()
		}
		let details_ref = /** @type {Readonly<Vue.ShallowRef<HTMLDetailsElement|null>>} */ (useTemplateRef('details_ref')) // eslint-disable-line no-extra-parens
		function on_mouse_up(/** @type {MouseEvent} */ event) {
			let target = event.target
			while (target instanceof Element && target.getAttribute('id') !== 'history' && target.parentElement)
				target = target.parentElement
			if (target instanceof Element && target.getAttribute('id') !== 'history')
				details_ref.value?.removeAttribute('open')
		}
		onMounted(() =>
			document.addEventListener('mouseup', on_mouse_up))
		onUnmounted(() =>
			document.removeEventListener('mouseup', on_mouse_up))

		return {
			details_ref,
			history_mapped,
			clear_history,
			remove_history_entry,
		}
	},
}
</script>
<style scoped>
details#history > summary {
	display: flex;
	align-items: center;
	justify-content: end;
}
details#history .dv {
	padding: 20px;
	background: #000;
}
details#history .dv li {
	overflow: hidden;
	padding: 5px 0;
	border-bottom: 1px solid #808080;
}
details#history .dv li .entry {
	overflow: hidden;
}
details#history .dv li .delete {
	margin-left: 5px;
}
</style>
