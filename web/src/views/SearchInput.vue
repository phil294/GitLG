<template>
	<section aria-roledescription="Search" class="center gap-5 justify-flex-end">
		<div class="center">
			<input ref="search_str_ref" v-model="search_str" type="text" class="search" :class="{highlighted:search_str}" placeholder="Search subject, hash, author" @keyup.enter="on_enter_jump($event)" @keyup.f3="on_enter_jump($event)">
			<button v-if="search_str" id="regex-search" :class="{highlighted:is_regex}" class="center" @click="is_regex=!is_regex">
				<i class="codicon codicon-regex" title="Use Regular Expression (Alt+R)" />
			</button>
		</div>
		<label v-if="search_str" id="search-type-filter" class="row align-center" title="If active, the list will be searched. If inactive, you can jump between matches with ENTER / SHIFT+ENTER or with F3 / SHIFT+F3.">
			<input v-model="type_is_filter" type="checkbox">
			Filter
		</label>
	</section>
</template>
<script setup>
import { computed, useTemplateRef, watch } from 'vue'
import { commit_matches_search, search_str, is_regex, type } from '../data/store/search'
import { commits } from '../data/store/repo'

let emit = defineEmits(['scroll_to_commit'])

let search_str_ref = useTemplateRef('search_str_ref')

let last_jump_index = -1
document.addEventListener('keyup', (e) => {
	if (e.key === 'F3' || e.ctrlKey && e.key === 'f')
		search_str_ref.value?.focus()

	if (search_str.value && e.key === 'r' && e.altKey)
		is_regex.value = ! is_regex.value
})
function on_enter_jump(/** @type {KeyboardEvent} */ event) {
	if (type.value === 'filter')
		return
	let next_match_index = 0
	if (event.shiftKey) {
		let next = [...commits.value.slice(0, last_jump_index)].reverse().findIndex(commit_matches_search)
		if (next > -1)
			next_match_index = last_jump_index - 1 - next
		else
			next_match_index = commits.value.length - 1
	} else {
		let next = commits.value.slice(last_jump_index + 1).findIndex(commit_matches_search)
		if (next > -1)
			next_match_index = last_jump_index + 1 + next
		else
			next_match_index = 0
	}
	alert(next_match_index)
	emit('scroll_to_commit', commits.value[next_match_index])
	last_jump_index = next_match_index
	// FIXME:
	// debounce(() => {
	// 	let commit = commits.value[txt_filter_last_i]
	// 	if (commit)
	// 		selected_commits.value = [commit]
	// }, 100)
}
watch(search_str, () => {
	if (type.value === 'jump')
		return
	debounce(() => {
		// FIXME
		// if (selected_commit.value)
		// 	scroll_to_commit(selected_commit.value)
	}, 250)
})

let type_is_filter = computed({
	get: () => type.value === 'filter',
	set: (v) => type.value = v ? 'filter' : 'jump',
})

</script>
<style scoped>
input[type="text"] {
	overflow: hidden;
}
#regex-search {
	min-width: 20px;
	margin: 0 7px 0 -23px;
}
</style>
