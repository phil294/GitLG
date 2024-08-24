import { computed, defineComponent } from 'vue'
import { exchange_message } from '../bridge.js'
import { stateful_computed, refresh_main_view } from './store.js'
import { createReusableTemplate } from '@vueuse/core'
import file_extension_icon_path_mapping from './file-extension-icon-path-mapping.json'

/** @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef */
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

// Doesn't point to the *actual* publicPath because VSCode proxies this somehow:
// base_url = process.env.BASE_URL
// In vue.config.js, it's set to `localhost:8080`, but that is for development only,
// and on production, the path is not deterministic. Is there a better solution?
// So we determine manually whatever `view.asWebviewUri` in `extension.js` has yielded this time,
// in this case by just copying the path from the last <script/> tag:
let base_url = (document.body.lastElementChild?.attributes.getNamedItem('src')?.value.match(/^(.+)\/js\/.+/)?.[1] || '') + '/'

/** @type {WritableComputedRef<'list'|'tree'>} */
let render_style = stateful_computed('files-diffs-list-render-style', 'list')

let [TemplateFileChangeDefine, TemplateFileChangeReuse] = createReusableTemplate()
let [TemplateFileActionsDefine, TemplateFileActionsReuse] = createReusableTemplate()
let [TemplateTreeNodeDefine, TemplateTreeNodeReuse] = createReusableTemplate()

export default defineComponent({
	components: { TemplateFileChangeDefine, TemplateFileChangeReuse, TemplateFileActionsDefine, TemplateFileActionsReuse, TemplateTreeNodeDefine, TemplateTreeNodeReuse },
	props: {
		files: {
			/** @type {() => FileDiff[]} */
			type: Array,
			required: true,
		},
	},
	emits: ['show_diff', 'view_rev'],
	setup(props) {
		let files = computed(() =>
			props.files.map((file) => {
				// Even on Windows, the delimiter of git paths output is forward slash
				let path_arr = file.path.split('/')
				// Icons have to be hardcoded because actual theme integration is more or less impossible:
				// https://github.com/microsoft/vscode/issues/183893
				let icon = file_extension_icon_path_mapping[file.path.split('.').at(-1)] || 'default_file.svg'
				return {
					...file,
					filename: path_arr.at(-1) || '?',
					dir: path_arr.slice(0, -1).join('/'),
					dir_arr: path_arr.slice(0, -1),
					icon_path: base_url + 'file-icons/' + icon,
				}
			}))
		let files_list = computed(() => {
			if (render_style?.value === 'list')
				return files.value
		})
		let files_tree = computed(() => {
			if (render_style?.value !== 'tree')
				return
			/** @type TreeNode */
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
			function unify(/** @type TreeNode */ curr) {
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

		function open_file(/** @type string */ filepath) {
			return exchange_message('open-file', { filename: filepath })
		}

		function show_file(/** @type string */ filepath) {
			return refresh_main_view({
				before_execute: (cmd) =>
					`${cmd} --follow -- "${filepath}"`,
			})
		}

		return {
			files_list,
			files_tree,
			render_style,
			open_file,
			show_file,
		}
	},
})
