import { ref, computed, defineComponent, watch } from 'vue'
import { exchange_message } from '../bridge.coffee'
import { stateful_computed } from './store.coffee'
import { createReusableTemplate } from '@vueuse/core'
import file_extension_icon_path_mapping from './file-extension-icon-path-mapping.json'

###* @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef ###
``###*
# @typedef {{
#	path: string
#	insertions: number
#	deletions: number
# }} FileDiff
###
``###*
# @typedef {{
#	children: Record<string, TreeNode>
#	files: FileDiff[]
#	path: string
# }} TreeNode
###

# Doesn't point to the *actual* publicPath because VSCode proxies this somehow:
# base_url = process.env.BASE_URL
# In vue.config.js, it's set to `localhost:8080`, but that is for development only,
# and on production, the path is not deterministic. Is there a better solution?
# So we determine manually whatever `view.asWebviewUri` in `extension.coffee` has yielded this time,
# in this case by just copying the path from the last <script/> tag:
base_url = (document.body.lastElementChild?.attributes.getNamedItem('src')?.value.match(/^(.+)\/js\/.+/)?[1] or '') + '/'

``###* @type {WritableComputedRef<'list'|'tree'>} ###
render_style = stateful_computed 'files-diffs-list-render-style', 'list'

[TemplateFileChangeDefine, TemplateFileChangeReuse] = createReusableTemplate()
[TemplateFileActionsDefine, TemplateFileActionsReuse] = createReusableTemplate()
[TemplateTreeNodeDefine, TemplateTreeNodeReuse] = createReusableTemplate()

export default defineComponent
	emits: ['show_diff', 'view_rev']
	components: { TemplateFileChangeDefine, TemplateFileChangeReuse, TemplateFileActionsDefine, TemplateFileActionsReuse, TemplateTreeNodeDefine, TemplateTreeNodeReuse }
	props:
		files:
			###* @type {() => FileDiff[]} ###
			type: Array
			required: true
	setup: (props) ->
		walkthrough_file_view_map = ref {}

		watch(
			() =>
				props.files
			() =>
				walkthrough_file_view_map.value = {}
				undefined
		)

		files = computed =>
			props.files.map (file) =>
				path_moved = file.path.split(' => ', 2)
				if path_moved.length == 2
					path1 = path_moved[0]
					path2 = path_moved[1]
					# Even on Windows, the delimiter of git paths output is forward slash
					path1_arr = path_moved[0].split('/')
					path2_arr = path_moved[1].split('/')
					# Icons have to be hardcoded because actual theme integration is more or less impossible:
					# https://github.com/microsoft/vscode/issues/183893
					icon = file_extension_icon_path_mapping[path_moved[1].split('.').at(-1)] or 'default_file.svg'
					file_desc = (path1_arr.at(-1) or '?') + ' => ' + path2
				else
					path1 = path_moved[0]
					path2 = path_moved[0]
					path1_arr = path_moved[0].split('/')
					path2_arr = path1_arr
					icon = file_extension_icon_path_mapping[path_moved[0].split('.').at(-1)] or 'default_file.svg'
					file_desc = (path1_arr.at(-1) or '?')
				return {
					...file
					path1: path1
					path2: path2
					filename1: path1_arr.at(-1) or '?'
					filename2: path2_arr.at(-1) or '?'
					dir: path1_arr.slice(0, -1).join('/')
					dir_arr: path1_arr.slice(0, -1)
					icon_path: base_url + 'file-icons/' + icon
					file_desc: file_desc
					is_viewed: false
				}
		files_list = computed =>
			files.value if render_style?.value == 'list'
		files_tree = computed =>
			return if render_style?.value != 'tree'
			``###* @type TreeNode ###
			out =
				children: {}
				files: []
				path: 'Changes'
			for file from files.value
				curr = out
				for dir_seg from file.dir_arr
					curr = curr.children[dir_seg] ?=
						children: {}
						files: []
						path: dir_seg
				curr.files.push file
			# Now all available dir segments have their own entry in the tree, but they
			# should be joined together as much as possible (i.e. when there are no files):
			unify = (###* @type TreeNode ### curr) =>
				modified_children = true
				while modified_children
					modified_children = false
					for child_i, child of curr.children
						if ! child.files.length
							for _, grand_child of child.children
								grand_child.path = child.path + ' / ' + grand_child.path
								curr.children[grand_child.path] = grand_child
							delete curr.children[child_i]
							modified_children = true
						else
							unify(child)
				undefined
			unify(out)
			out

		mark_file_viewed = (file) =>
			walkthrough_file_view_map.value[file.path2] = true

		open_file = (###* @type string ### filepath) =>
			exchange_message 'open-file',
				filename: filepath

		{
			walkthrough_file_view_map
			files_list
			files_tree
			render_style
			mark_file_viewed
			open_file
		}