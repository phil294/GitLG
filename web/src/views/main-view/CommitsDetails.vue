<template>
	<div class="commits-details">
		<div class="row fill-h">
			<div class="left flex-1">
				<h3>
					<!-- TODO: styling -->
					{{ commits.length }} commits selected
					<span class="actions-menu" @click.stop>
						<button v-context-menu="commits_context_menu_provider" class="ellipsis-btn" @click="trigger_commits_context_menu($event)">⋯</button>
					</span>
				</h3>
				<div class="commit-hashes">
					<div v-for="commit in commits" :key="commit.hash" class="commit-hash-line">
						<a class="commit-hash-link" title="Jump to commit" @click="$emit('hash_clicked', commit.hash)">{{ commit.hash }}</a>
					</div>
				</div>
				<template v-if="details_panel_position !== 'bottom'">
					<template v-if="commits.length===2">
						<commit-diff :commit1="commits[0]" :commit2="commits[1]" />
					</template>
				</template>
			</div>
			<div :class="details_panel_position === 'bottom' ? 'flex-1' : ''" class="right">
				<template v-if="details_panel_position === 'bottom'">
					<template v-if="commits.length===2">
						<commit-diff :commit1="commits[0]" :commit2="commits[1]" />
					</template>
				</template>
			</div>
		</div>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { commits_actions as commits_actions_ } from '../../data/store/actions'
import { selected_git_action } from '../../data/store/index.js'
import config from '../../data/store/config.js'
import vContextMenu from '../../directives/context-menu'

let props = defineProps({
	commits: {
		/** @type {Vue.PropType<Commit[]>} */
		type: Array,
		required: true,
	},
})

defineEmits(['hash_clicked'])

let details_panel_position = computed(() =>
	config.get_string('details-panel-position'))

let commits_actions = computed(() => commits_actions_(props.commits.map((c) => c.hash)).value)

function to_context_menu_entries(/** @type {GitAction[]} */ actions) {
	return actions.map((action) => ({
		label: action.title,
		icon: action.icon,
		action() {
			selected_git_action.value = action
		},
	}))
}

let commits_context_menu_provider = computed(() => () => to_context_menu_entries(commits_actions.value))

function trigger_commits_context_menu(/** @type {MouseEvent} */ event) {
	// Simulate right-click to trigger the existing context menu
	let contextEvent = new MouseEvent('contextmenu', {
		bubbles: true,
		cancelable: true,
		clientX: event.clientX,
		clientY: event.clientY,
	})
	event.target?.dispatchEvent(contextEvent)
}
</script>
<style scoped>
.actions-menu { position: relative; display: inline-flex; align-items: stretch; }
.ellipsis-btn { cursor: pointer; border: 1px solid var(--vscode-editorWidget-border,#555); background: var(--vscode-editor-background,#222); color: inherit; padding: 1px 6px; border-radius: 7px; display:inline-flex; align-items:center; line-height:1; height:100%; vertical-align:middle; font-size:inherit; margin-left: 10px; }
.commit-hashes { margin: 10px 0; }
.commit-hash-line {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 4px;
	font-family: monospace;
}
.commit-hash-link {
	color: var(--vscode-textLink-foreground, #4daafc);
	cursor: pointer;
	text-decoration: none;
	font-family: monospace;
}
.commit-hash-link:hover {
	text-decoration: underline;
}
.left,
.right {
	overflow: auto;
}
.row {
	display: flex;
}
.fill-h {
	height: 100%;
}
.flex-1 {
	flex: 1;
}
</style>
