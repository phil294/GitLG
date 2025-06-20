<template>
	<recycle-scroller
		ref="scroller_ref"
		v-slot="{ item: commit }"
		v-context-menu="commit_context_menu_provider"
		:buffer="0"
		:emit-update="true"
		:item-size="item_height"
		:items="commits"
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
			@click="emit('commit_clicked',commit,$event)"
		/>
	</recycle-scroller>
</template>
<script setup>
import { computed, onMounted, useTemplateRef, watch } from 'vue'
import { config, selected_git_action } from '../../data/store'
import { commits, visible_commits } from '../../data/store/repo'
import { commit_actions } from '../../data/store/actions'
import { exchange_message } from '../../bridge'
import vContextMenu from '../../directives/context-menu'
import { is_regex as search_is_regex, search_str, str_index_of_search } from '../../data/store/search'

let { selected_commits } = defineProps({
	selected_commits: {
		required: true,
		/** @type {Vue.PropType<Commit[]>} */
		type: Array,
	},
})

let emit = defineEmits(['commit_clicked'])

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
		visible_commits.value = commits.value.slice(commits_start_index, to), 50)
}
function on_wheel(/** @type {WheelEvent} */ event) {
	if (config.value['disable-scroll-snapping'])
		return
	event.preventDefault()
	scroll_to_item(visible_start_index + Math.round(event.deltaY / 20))
}
function on_keydown(/** @type {KeyboardEvent} */ event) {
	if (config.value['disable-scroll-snapping'])
		return
	if (event.key === 'ArrowDown') {
		event.preventDefault()
		scroll_to_item(visible_start_index + 2)
	} else if (event.key === 'ArrowUp') {
		event.preventDefault()
		scroll_to_item(visible_start_index - 2)
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
	background: var(--vscode-list-activeSelectionBackground);
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
