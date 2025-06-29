<template>
	<section aria-roledescription="Search" class="center gap-5 justify-flex-end" :inert="web_phase==='refreshing'">
		<div class="center">
			<input ref="search_str_ref" v-model="search_str" type="text" class="search" :class="{highlighted:search_str}" placeholder="Search subject, hash, author, file contents, branches..." @keyup.enter="on_enter_jump($event)" @keyup.f3="on_enter_jump($event)">
			<button v-if="search_str && where === 'immediate'" id="option-regex" :class="{highlighted:is_regex}" class="center" @click="is_regex=!is_regex">
				<i class="codicon codicon-regex" title="Use Regular Expression (Alt+R)" />
			</button>
		</div>
		<label v-if="search_str && where === 'immediate'" id="search-type-filter" class="row align-center" title="If active, the list will be searched. If inactive, you can jump between matches with ENTER / SHIFT+ENTER or with F3 / SHIFT+F3.">
			<input v-model="type_is_filter" type="checkbox">
			Filter
		</label>
		<select v-if="search_str" id="option-where" v-model="where">
			<option value="immediate">
				Subject, hash, author, mail, branches, stashes, tags (fast)
			</option>
			<option value="body">
				Body (slow)
			</option>
			<option value="file_names">
				File names (slow)
			</option>
			<option value="file_contents">
				File contents (very slow)
			</option>
		</select>
	</section>
</template>
<script setup>
import { computed, useTemplateRef } from 'vue'
import { commit_matches_immediate_search, search_str, is_regex, type, where } from '../../data/store/search'
import { filtered_commits } from '../../data/store/repo'
import { web_phase } from '../../data/store'

let emit = defineEmits(['jump_to_commit'])

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
		let next = [...filtered_commits.value.slice(0, last_jump_index)].reverse().findIndex(commit_matches_immediate_search)
		if (next > -1)
			next_match_index = last_jump_index - 1 - next
		else
			next_match_index = filtered_commits.value.length - 1
	} else {
		let next = filtered_commits.value.slice(last_jump_index + 1).findIndex(commit_matches_immediate_search)
		if (next > -1)
			next_match_index = last_jump_index + 1 + next
		else
			next_match_index = 0
	}
	emit('jump_to_commit', filtered_commits.value[next_match_index])
	last_jump_index = next_match_index
}

let type_is_filter = computed({
	get: () => type.value === 'filter',
	set: (v) => type.value = v ? 'filter' : 'jump',
})

</script>
<style scoped>
input.search {
	overflow: hidden;
	width: 210px;
}
#option-regex {
	min-width: 20px;
	margin: 0 7px 0 -23px;
}
#option-where {
	max-width: 150px;
}
</style>
