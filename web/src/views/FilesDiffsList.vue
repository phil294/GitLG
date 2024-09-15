<template>
	<!-- TODO rename to filesdiffs, incl class -->
	<div class="files-diffs-list">
		<h3>
			Changes ({{ files.length }})
		</h3>
		<aside class="actions">
			<button v-if="render_style==='tree'" title="View as list" @click="render_style='list'">
				<i class="codicon codicon-list-tree" />
			</button>
			<button v-else title="View as tree" @click="render_style='tree'">
				<i class="codicon codicon-list-flat" />
			</button>
		</aside>
		<template-file-change-define v-slot="{ file }">
			<button :title="file.insertions+' insertions, '+file.deletions+' deletions'" class="change center gap-10">
				<div v-if="file.is_creation" class="align-center grey" title="This file was added">
					<i class="codicon codicon-add" />
				</div>
				<div v-if="file.is_deletion" class="align-center grey" title="This file was deleted">
					<i class="codicon codicon-trash" />
				</div>
				<progress :value="(file.insertions / (file.insertions + file.deletions)) || 0" class="diff" />
				<div class="count">
					{{ (file.insertions + file.deletions) || 0 }}
				</div>
			</button>
		</template-file-change-define>
		<template-file-actions-define v-slot="{ file }">
			<div class="file-actions row align-center">
				<button class="row show-file" title="Show file history" @click.stop="show_file(file.path)">
					<i class="codicon codicon-history" />
				</button>
				<button class="row view-rev" title="View File at this Revision" @click.stop="$emit('view_rev',file.path)">
					<i class="codicon codicon-git-commit" />
				</button>
				<button class="row open-file" title="Open file" @click.stop="open_file(file.path)">
					<i class="codicon codicon-go-to-file" />
				</button>
			</div>
		</template-file-actions-define>
		<ul v-if="files_list" class="list">
			<li v-for="file of files_list" :key="file.path" class="list-row flex-1 row align-center gap-10" role="button" @click="$emit('show_diff',file.path)">
				<div class="flex-1 fill-h row align-center gap-10">
					<img :src="file.icon_path" aria-hidden="true">
					<div :title="file.filename" class="filename">
						{{ file.filename }}
					</div>
					<div :title="file.dir" class="dir">
						{{ file.dir }}
					</div>
				</div>
				<template-file-actions-reuse :file="file" />
				<template-file-change-reuse :file="file" />
			</li>
		</ul>
		<template-tree-node-define v-slot="{ node }">
			<details class="tree-node" open>
				<summary :title="node.path">
					{{ node.path }}
				</summary>
				<div class="body">
					<template-tree-node-reuse v-for="child of node.children" :key="child.path" :node="child" />
					<template v-for="file of node.files" :key="file.path">
						<button class="fill-w row align-center gap-10" @click="$emit('show_diff',file.path)">
							<img :src="file.icon_path" aria-hidden="true">
							<div :title="file.filename" class="filename flex-1">
								{{ file.filename }}
							</div>
							<template-file-actions-reuse :file="file" />
							<template-file-change-reuse :file="file" />
						</button>
					</template>
				</div>
			</details>
		</template-tree-node-define>
		<div v-if="files_tree" class="tree">
			<template-tree-node-reuse :node="files_tree" />
		</div>
	</div>
</template>
<script setup>
import { computed } from 'vue'
import { exchange_message } from '../bridge.js'
import { stateful_computed, refresh_main_view } from '../state/store.js'
import { createReusableTemplate } from '@vueuse/core'
import file_extension_icon_path_mapping from '../state/file-extension-icon-path-mapping.json'

/**
 * @typedef {{
 *	path: string
 *	insertions: number
 *	deletions: number
 * }} FileDiff
 */
/**
 * @typedef {{
 *	children: Record<string, TreeNode>
 *	files: FileDiff[]
 *	path: string
 * }} TreeNode
 */

/** @type {Vue.WritableComputedRef<'list'|'tree'>} */
let render_style = stateful_computed('files-diffs-list-render-style', 'list')

let [TemplateFileChangeDefine, TemplateFileChangeReuse] = createReusableTemplate()
let [TemplateFileActionsDefine, TemplateFileActionsReuse] = createReusableTemplate()
let [TemplateTreeNodeDefine, TemplateTreeNodeReuse] = createReusableTemplate()

let props = defineProps({
	files: {
		/** @type {Vue.PropType<FileDiff[]>} */
		type: Array,
		required: true,
	},
})
defineEmits(['show_diff', 'view_rev'])

let files = computed(() =>
	props.files.map((file) => {
		// Even on Windows, the delimiter of git paths output is forward slash
		let path_arr = file.path.split('/')
		// Icons have to be hardcoded because actual theme integration is more or less impossible:
		// https://github.com/microsoft/vscode/issues/183893
		let icon = file_extension_icon_path_mapping[/** @type {keyof file_extension_icon_path_mapping} */(file.path.split('.').at(-1) || '')] || 'default_file.svg' // eslint-disable-line @stylistic/no-extra-parens
		return {
			...file,
			filename: path_arr.at(-1) || '?',
			dir: path_arr.slice(0, -1).join('/'),
			dir_arr: path_arr.slice(0, -1),
			icon_path: './file-icons/' + icon,
		}
	}))
let files_list = computed(() => {
	if (render_style?.value === 'list')
		return files.value
})
let files_tree = computed(() => {
	if (render_style?.value !== 'tree')
		return
	/** @type {TreeNode} */
	let out = {
		children: {},
		files: [],
		path: 'Changes',
	}
	for (let file of files.value) {
		let curr = out
		for (let dir_seg of file.dir_arr)
			curr = curr.children[dir_seg] ||= {
				children: {},
				files: [],
				path: dir_seg,
			}
		curr.files.push(file)
	}
	// Now all available dir segments have their own entry in the tree, but they
	// should be joined together as much as possible (i.e. when there are no files):
	function unify(/** @type {TreeNode} */ curr) {
		let modified_children = true
		while (modified_children) {
			modified_children = false
			for (let [child_i, child] of Object.entries(curr.children))
				if (! child.files.length) {
					for (let grand_child of Object.values(child.children)) {
						grand_child.path = child.path + ' / ' + grand_child.path
						curr.children[grand_child.path] = grand_child
					}
					delete curr.children[child_i]
					modified_children = true
				} else
					unify(child)
		}
	}
	unify(out)
	return out
})

function open_file(/** @type {string} */ filepath) {
	return exchange_message('open-file', { filename: filepath })
}

function show_file(/** @type {string} */ filepath) {
	return refresh_main_view({
		before_execute: (cmd) =>
			`${cmd} --follow -- "${filepath}"`,
	})
}

</script>
<style scoped>
.files-diffs-list {
	position: relative;
}
.files-diffs-list .change {
	flex-shrink: 0;
	font-family: monospace;
	font-size: 90%;
}
.files-diffs-list .change > .count {
	width: 2rem;
}
.files-diffs-list .filename {
	white-space: pre;
	overflow: hidden;
	text-overflow: ellipsis;
	color: #e5b567;
	flex-shrink: 0;
}
.files-diffs-list ul.list > li {
	padding-left: 10px;
	position: relative;
}
.files-diffs-list ul.list > li .dir {
	font-size: 0.9em;
	opacity: 0.7;
	white-space: pre;
	overflow: hidden;
	text-overflow: ellipsis;
}
.files-diffs-list .tree-node {
	position: relative;
}
.files-diffs-list aside.actions {
	opacity: 0;
	position: absolute;
	top: 0;
	right: 0;
}
.files-diffs-list:hover aside.actions {
	opacity: 1;
}
.files-diffs-list .file-actions {
	display: none;
}
.files-diffs-list .list-row,
.files-diffs-list .tree-node > summary,
.files-diffs-list .tree-node > .body > .row {
	height: 20px;
}
.files-diffs-list .list-row:hover,
.files-diffs-list .tree-node > summary:hover,
.files-diffs-list .tree-node > .body > .row:hover {
	background: #2a2d2e;
}
.files-diffs-list .list-row:hover > .file-actions,
.files-diffs-list .tree-node > summary:hover > .file-actions,
.files-diffs-list .tree-node > .body > .row:hover > .file-actions {
	display: flex;
}
.files-diffs-list .tree-node > .body {
	padding-left: 20px;
}
</style>
