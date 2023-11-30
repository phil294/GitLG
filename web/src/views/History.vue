<template lang="slm">
details#history.center ref="details_ref"
	summary
		| History...
	div.dv
		div v-if="history_mapped.length"
			.flex.justify-flex-end
				button.btn#clear-history @click="clear_history"
					i.codicon.codicon-trash
					|  Clear repository history
			ol.entries
				li.flex v-for="(entry, entry_i) of history_mapped"
					.entry.flex-1 :title="entry.datetime"
						commit-row v-if="entry.type == 'commit_hash' && entry.ref" :commit="entry.ref" role="button" @click="$emit('commit_clicked', entry.ref)"
						div v-else-if="entry.type == 'commit_hash'"
							| Commit '{{ entry.value }}' not found!
						git-action-button v-else-if="entry.type == 'git'" :git_action="entry.ref"
						button.btn v-else-if="entry.type == 'txt_filter'" @click="$emit('apply_txt_filter', entry.value)"
							i.codicon.codicon-search
							|  Search: <code>{{ entry.value }}</code>
						div v-else=""
							| Unknown history entry: {{ entry.value }}
					.delete
						button.btn @click="remove_history_entry(entry_i)" title="Remove this item from the repository history"
							i.codicon.codicon-trash
		p v-else=""
			| Repository history empty!
</template>

<script lang="coffee">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { history, commits } from './store.coffee'
import CommitRow from './CommitRow.vue'
import GitActionButton from './GitActionButton.vue'

export default
	emits: ['commit_clicked', 'apply_txt_filter']
	components: { CommitRow, GitActionButton }
	setup: ->
		history_mapped = computed =>
			(history.value || []).slice().reverse().map (entry) =>
				type: entry.type
				value: entry.value
				datetime: entry.datetime
				ref:
					switch entry.type
						when 'commit_hash'
							commits.value?.find (commit) =>
								commit.hash == entry.value
						when 'git'
							title: 'git ' + entry.value
							args: entry.value
							description: 'History entry'
							icon: 'history'
		clear_history = =>
			history.value = []
		remove_history_entry = (###* @type number ### entry_i) =>
			history.value.splice(history.value.length - entry_i - 1, 1)
			history.value = history.value.slice()
		details_ref = ref null
		on_mouse_up = (###* @type MouseEvent ### event) =>
			target = event.target
			while target instanceof Element and target.getAttribute('id') != 'history' and target.parentElement
				target = target.parentElement
			if target instanceof Element and target.getAttribute('id') != 'history'
				# @ts-ignore TODO: .
				details_ref.value?.removeAttribute 'open'
		onMounted =>
			document.addEventListener 'mouseup', on_mouse_up
		onUnmounted =>
			document.removeEventListener 'mouseup', on_mouse_up
		{
			details_ref
			history_mapped
			clear_history
			remove_history_entry
		}
</script>

<style lang="stylus" scoped>
details#history
	> summary
		display flex
		align-items center
		justify-content end
	.dv
		padding 20px
		background black
		li
			overflow hidden
			padding 5px 0
			border-bottom 1px solid grey
			.entry
				overflow hidden
			.delete
				margin-left 5px
</style>