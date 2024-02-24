import { computed, defineComponent } from 'vue'
import { exchange_message } from '../bridge.coffee'
import { stateful_computed, refresh_main_view } from './store.coffee'
import { createReusableTemplate } from '@vueuse/core'
import file_extension_icon_path_mapping from './file-extension-icon-path-mapping.json'

###* @template T @typedef {import('vue').WritableComputedRef<T>} WritableComputedRef ###
###*
# @typedef {{
#	path: string
#	insertions: number
#	deletions: number
# }} FileDiff
###
###*
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

###* @type {WritableComputedRef<'list'|'tree'>} ###
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
		files = computed =>
			props.files.map (file) =>
				# Even on Windows, the delimiter of git paths output is forward slash
				path_arr = file.path.split('/')
				# Icons have to be hardcoded because actual theme integration is more or less impossible:
				# https://github.com/microsoft/vscode/issues/183893
				icon = file_extension_icon_path_mapping[file.path.split('.').at(-1)] or 'default_file.svg'
				{
					...file
					filename: path_arr.at(-1) or '?'
					dir: path_arr.slice(0, -1).join('/')
					dir_arr: path_arr.slice(0, -1)
					icon_path: base_url + 'file-icons/' + icon
				}
		files_list = computed =>
			files.value if render_style?.value == 'list'
		files_tree = computed =>
			return if render_style?.value != 'tree'
			###* @type TreeNode ###
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

		open_file = (###* @type string ### filepath) =>
			exchange_message 'open-file',
				filename: filepath

		show_file = (###* @type string ### filepath) =>
			refresh_main_view before_execute: (cmd) =>
				"#{cmd} -- \"#{filepath}\""

		{
			files_list
			files_tree
			render_style
			open_file
			show_file
		}