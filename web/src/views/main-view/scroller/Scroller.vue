<template>
	<recycle-scroller
		ref="scroller_ref"
		v-slot="{ item: commit }"
		v-context-menu="commit_context_menu_provider"
		:buffer="0"
		:emit-update="true"
		:item-size="item_height"
		:items="filtered_commits"
		class="scroller fill-w flex-1"
		key-field="index_in_graph_output"
		role="list"
		tabindex="-1"
		@keydown="on_keydown"
		@update="on_update"
		@wheel="on_wheel"
	>
		<commit-row
			:class="{['selected-commit']: selected_commits.includes(commit)}"
			:commit="commit"
			:data-commit-hash="commit.hash"
			@click="commit_clicked(commit,$event)"
		/>
	</recycle-scroller>
</template>
<script setup>
import { computed, onMounted, useTemplateRef, watch } from 'vue'
import { config, selected_git_action } from '../../../data/store'
import { filtered_commits, selected_commits, visible_commits } from '../../../data/store/repo'
import { commit_actions } from '../../../data/store/actions'
import { exchange_message } from '../../../bridge'
import vContextMenu from '../../../directives/context-menu'
import { is_regex as search_is_regex, search_str, str_index_of_search } from '../../../data/store/search'
import { push_history } from '../../../data/store/history'

// @ts-ignore TODO: idk
let scroller_ref = /** @type {Readonly<Vue.ShallowRef<InstanceType<typeof import('vue-virtual-scroller').RecycleScroller>|null>>} */ (useTemplateRef('scroller_ref'))
onMounted(() => {
	scroller_ref.value.$el.focus()
})
let scroll_to_item = (/** @type {number} */ item) =>
	scroller_ref.value?.scrollToItem(item)
let item_height = computed(() =>
	config.value['row-height'])
let visible_start_index = 0
function on_update(/** @type {number} */ from, /** @type {number} */ to) {
	visible_start_index = from
	let commits_start_index = visible_start_index < 3 ? 0 : visible_start_index
	debounce(() =>
		visible_commits.value = filtered_commits.value.slice(commits_start_index, to), 50)
}
let scroll_delta_acc = 0
function on_wheel(/** @type {WheelEvent} */ event) {
	if (config.value['disable-scroll-snapping'])
		return
	event.preventDefault()
	scroll_delta_acc += event.deltaY
	if (Math.abs(scroll_delta_acc) > 40) {
		// might not be updated correctly by on_update so it needs to be set here either way
		visible_start_index += Math.round(scroll_delta_acc / 20)
		scroll_delta_acc = 0
		scroll_to_item(visible_start_index)
	}
}
function on_keydown(/** @type {KeyboardEvent} */ event) {
	if (config.value['disable-scroll-snapping'])
		return
	if (event.key === 'ArrowDown') {
		event.preventDefault()
		visible_start_index += 2 // ^
		scroll_to_item(visible_start_index)
	} else if (event.key === 'ArrowUp') {
		event.preventDefault()
		visible_start_index -= 2 // ^
		scroll_to_item(visible_start_index)
	}
}

// It didn't work with normal context binding to the scroller's commit elements, either a bug
// of context-menu update or I misunderstood something about vue-virtual-scroller, but this
// works around it reliably (albeit uglily)
let commit_context_menu_provider = computed(() => (/** @type {MouseEvent} */ event) => {
	if (! (event.target instanceof HTMLElement) && ! (event.target instanceof SVGElement))
		return
	let el = event.target
	while (el.parentElement && ! el.parentElement.classList.contains('commit'))
		el = el.parentElement
	if (! el.parentElement)
		return
	let hash = el.parentElement.dataset.commitHash
	if (! hash)
		throw 'commit context menu element has no hash?'
	return commit_actions(hash).value.map((action) => ({
		label: action.title,
		icon: action.icon,
		action() {
			selected_git_action.value = action
		},
	})).concat({
		label: 'Copy hash',
		icon: 'clippy',
		action() {
			exchange_message('clipboard-write-text', hash)
		},
	})
})

function update_highlights() {
	CSS.highlights.delete('search')
	if (! search_str.value)
		return
	// This also queries hidden rows regardless of current search, depending on viewport height.
	// Not great on performance but this one-liner is by far the easiest way of getting highlights:
	let highlight_ranges = [...scroller_ref.value.$el.querySelectorAll('.ref-tip, .subject, .author, .hash')]
		.map(node => ({ node, index: str_index_of_search(node.textContent) }))
		.filter(n => n.index > -1)
		.map(({ node, index }) => new StaticRange({ startContainer: node.childNodes[0], startOffset: index, endContainer: node.childNodes[0], endOffset: index + search_str.value.length }))
	if (highlight_ranges.length > 0)
		CSS.highlights.set('search', new Highlight(...highlight_ranges))
}
// TODO: use useEffect if possible
watch([search_str, visible_commits, search_is_regex], () => {
	update_highlights()
	// In vue-virtual-scroller.esm.js in updateVisibleItems, _$_sortTimer will fire after 300ms and force reselection.
	// You shouldn't alter a virtual scroller's items from outside anyway...
	debounce(update_highlights, 300 + 1)
})

/** Manages commit selection similar to e.g. Windows file explorer */
function commit_clicked(/** @type {Commit} */ commit, /** @type {MouseEvent | undefined} */ event) {
	if (! commit.hash)
		return
	let selected_index = selected_commits.value.indexOf(commit)
	if (event?.ctrlKey || event?.metaKey)
		if (selected_index > -1)
			selected_commits.value = selected_commits.value.filter((_, i) => i !== selected_index)
		else
			selected_commits.value = [...selected_commits.value, commit]
	else if (event?.shiftKey) {
		let total_index = filtered_commits.value.indexOf(commit)
		let last_total_index = filtered_commits.value.indexOf(not_null(selected_commits.value.at(-1)))
		if (total_index > last_total_index && total_index - last_total_index < 1000)
			selected_commits.value = selected_commits.value.concat(filtered_commits.value.slice(last_total_index, total_index + 1).filter((c) =>
				! selected_commits.value.includes(c)))
	} else
		if (selected_index > -1)
			selected_commits.value = []
		else {
			selected_commits.value = [commit]
			push_history({ type: 'commit_hash', value: commit.hash })
		}
}

onMounted(() => {
	// didn't work with @keyup.escape.native on the components root element
	// when focus was in a sub component (??) so doing this instead:
	document.addEventListener('keyup', (e) => {
		if (e.key === 'Escape')
			selected_commits.value = []
	})
})

defineExpose({ scroll_to_item })

</script>

<style scoped>
/* TODO: ? */
.scroller:focus {
	outline: none;
}
.commit {
	padding-left: var(--container-padding);
	cursor: pointer;
}
.commit.selected-commit {
	background: var(--vscode-list-activeSelectionBackground) !important;
	.vscode-high-contrast &, .vscode-high-contrast-light & {
		border: 1px solid var(--vscode-sideBarSectionHeader-border);
	}
}
.commit :deep(.info) {
	border-top: 1px solid var(--vscode-sideBarSectionHeader-border);
	padding-right: var(--container-padding);
}
.commit :deep(.info:hover) {
	z-index: 1;
}
</style>

<style>
.vue-recycle-scroller__item-view.hover > .commit {
	background: var(--vscode-list-hoverBackground);
}
</style>
