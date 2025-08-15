<template>
	<div class="commit-details">
		<div class="row fill-h">
			<div class="left flex-1">
				<h3>
					Commit
					<span v-if="config_show_buttons" class="actions-menu" @click.stop>
						<button v-context-menu="commit_context_menu_provider" class="ellipsis-btn" @click="trigger_commit_context_menu($event)">⋯</button>
					</span>
				</h3>

				<div v-if="commit.stash && config_show_buttons" class="stash">
					<h3 class="stash-head">
						Stash: <code>{{ commit.stash.name }}</code>
						<span class="actions-menu" @click.stop>
							<button class="ellipsis-btn" @click="trigger_ref_context_menu($event, 'stash', commit.stash)">⋯</button>
						</span>
					</h3>
				</div>
				<div v-if="refs_combined.length" class="refs">
					<commit-ref-tips
						class="refs-inline gap-5"
						:commit="commit"
						:refs="refs_combined"
						:allow_wrap="true"
						:show_buttons="config_show_buttons"
						:ref_title="tag_title"
					/>
				</div>

				<div class="commit-details-info">
					<div class="commit-details-hash">
						Hash: <a class="commit-hash-link" title="Jump to commit" @click="$emit('hash_clicked',commit.hash)">{{ commit.hash_long }}</a>
					</div>
					<div class="commit-details-parents">
						Parents:
						<span v-for="parent_hash of parent_hashes" :key="parent_hash" class="parent-inline">
							<a class="commit-hash-link" title="Jump to commit" @click="$emit('hash_clicked',parent_hash)">{{ parent_hash }}</a>
						</span>
					</div>
					<div class="commit-details-author">
						Author: {{ author_name }} <span v-if="author_email">&lt;{{ author_email }}&gt;</span>
						<br>
						Date: {{ author_date }}
					</div>
					<template v-if="!same_author_committer">
						<div class="commit-details-committer">
							Committer: {{ committer_name }} <span v-if="committer_email">&lt;{{ committer_email }}&gt;</span>
							<br>
							Date: {{ committer_date }}
						</div>
					</template>
					<div class="commit-details-summary">
						<p class="summary-line">
							{{ commit.subject }}
						</p>
					</div>
					<div class="commit-details-body">
						<p class="body">
							{{ body }}
						</p>
					</div>
				</div>
				<template v-if="details_panel_position !== 'bottom'">
					<commit-diff :commit1="commit" />
				</template>
			</div>
			<!-- TODO: fix this duplication with css -->
			<div :class="details_panel_position === 'bottom' ? 'flex-1' : ''" class="right">
				<template v-if="details_panel_position === 'bottom'">
					<commit-diff :commit1="commit" />
				</template>
			</div>
		</div>
	</div>
</template>

<script setup>
import { ref, computed, watchEffect } from 'vue'
import { git } from '../../bridge.js'
import { commit_actions as commit_actions_ } from '../../data/store/actions.js'
import config from '../../data/store/config.js'
import { selected_git_action } from '../../data/store/index.js'
import vContextMenu from '../../directives/context-menu'

let props = defineProps({
	commit: {
		/** @type {Vue.PropType<Commit>} */
		type: Object,
		required: true,
	},
})
defineEmits(['hash_clicked'])

let details_panel_position = computed(() =>
	config.get_string('details-panel-position'))

let tags = computed(() => props.commit.refs.filter((ref_) =>
	ref_.type === 'tag'))
/** @type {Vue.Ref<string[]>} */
let tag_details = ref([])
// Map ref.id -> tooltip text for tags so CommitRefTips can render title
let tag_tooltip_by_id = computed(() => new Map(tags.value.map((t, i) => [t.id, tag_details.value[i]])))

// Combined refs (branches + tags) in original order from parser
let refs_combined = computed(() => props.commit.refs)

/** @param {GitRef} r */
function tag_title(r) {
	return tag_tooltip_by_id.value.get(r.id)
}

let body = ref('')
/** @type {Vue.Ref<string[]>} */
let parent_hashes = ref([])

let author_name = ref('')
let author_email = ref('')
let author_date = ref('')
let committer_name = ref('')
let committer_email = ref('')
let committer_date = ref('')

function trigger_ref_context_menu(/** @type {MouseEvent} */ event, /** @type {string} */ _type, /** @type {GitRef=} */ _git_ref) {
	// Find the ref-tip element to trigger its context menu
	let ref_tip_element = /** @type {HTMLElement} */ (event.target)?.closest('.ref-item')?.querySelector('.ref-tip')
	if (ref_tip_element) {
		// Create synthetic right-click event on the ref-tip
		let context_event = new MouseEvent('contextmenu', {
			bubbles: true,
			cancelable: true,
			clientX: event.clientX,
			clientY: event.clientY,
		})
		ref_tip_element.dispatchEvent(context_event)
	}
}

function to_context_menu_entries(/** @type {GitAction[]} */ actions) {
	return actions.map((action) => ({
		label: action.title,
		icon: action.icon,
		action() {
			selected_git_action.value = action
		},
	}))
}

let commit_context_menu_provider = computed(() => () => to_context_menu_entries(commit_actions_(props.commit.hash).value))

function trigger_commit_context_menu(/** @type {MouseEvent} */ event) {
	// Simulate right-click to trigger the existing context menu
	let contextEvent = new MouseEvent('contextmenu', {
		bubbles: true,
		cancelable: true,
		clientX: event.clientX,
		clientY: event.clientY,
	})
	event.target?.dispatchEvent(contextEvent)
}

let same_author_committer = computed(() =>
	author_name.value === committer_name.value &&
	author_email.value === committer_email.value &&
	author_date.value === committer_date.value)

watchEffect(async () => {
	body.value = await git(`show -s --format="%b" ${props.commit.hash}`)

	tag_details.value = []
	for (let tag of tags.value) {
		let details = await git('show --format="" --quiet --color=never refs/tags/' + tag.name)
		tag_details.value.push(details)
	}

	parent_hashes.value = ((await git(`log --pretty=%p -n 1 ${props.commit.hash}`))).split(' ')

	// Fetch author/committer details in one go separated by unit separator
	try {
		let meta = await git(`show -s --format="%an%x1f%ae%x1f%aI%x1f%cn%x1f%ce%x1f%cI" ${props.commit.hash}`)
		let [an, ae, aI, cn, ce, cI] = meta.split('\u001f')
		author_name.value = an || ''
		author_email.value = ae || ''
		author_date.value = aI || ''
		committer_name.value = cn || ''
		committer_email.value = ce || ''
		committer_date.value = cI || ''
	} catch (e) {
		console.error(`Failed to fetch commit metadata: ${e}`)
	}
})

let config_show_buttons = computed(() =>
	! config.get_boolean_or_undefined('hide-sidebar-buttons'))
</script>
<style scoped>
h3 {
	margin-bottom: 5px;
}
.summary-line {
	white-space: pre-line;
	word-break: break-word;
	font-weight: bold;
	margin: 10px 0 0;
}
.body {
	white-space: pre-wrap;
	word-break: break-word;
}
.parent-inline { margin-right: 8px; }
.commit-hash-link {
	color: var(--vscode-textLink-foreground, #4daafc);
	cursor: pointer;
	text-decoration: none;
	font-family: monospace;
}
.commit-hash-link:hover {
	text-decoration: underline;
}
.refs-inline {
	display: flex;
	flex-wrap: nowrap;
	overflow-x: auto;
	gap: 12px;
	padding: 4px 0;
}
.ref-item { display: flex; flex-direction: column; align-items: flex-start; }
.ref-head { display:flex; align-items:center; gap:6px; }
.ref-item .actions { flex-wrap: nowrap; }
.actions-menu { position: relative; display: inline-flex; align-items: stretch; }
.ellipsis-btn { cursor: pointer; border: 1px solid var(--vscode-editorWidget-border,#555); background: var(--vscode-editor-background,#222); color: inherit; padding: 1px 6px; border-radius: 7px; display:inline-flex; align-items:center; line-height:1; height:100%; vertical-align:middle; font-size:inherit; }
.ref-head, .stash-head { display:flex; align-items:center; gap:6px; }
.ref-head .actions-menu, .stash-head .actions-menu { height:100%; }
.left,
.right {
	overflow: auto;
}
</style>
