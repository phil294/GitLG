import { computed, defineComponent } from 'vue'
import FilesDiffsListRow from './FilesDiffsListRow.vue'
import FilesDiffsListTreeNode from './FilesDiffsListTreeNode.vue'

``###*
# @typedef {{
#	path: string
#	insertions: number
#	deletions: number
# }} FileDiff
###

render_style = stateful_computed 'files-diffs-list-render-style', 'list'

export default defineComponent
	emits: ['show_diff', 'view_ref']
	components: { FilesDiffsListRow, FilesDiffsListTreeNode }
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
				{
					...file
					filename: path_arr.at(-1) or '?'
					dir: path_arr.slice(0, -1).join('/')
					dir_arr: path_arr.slice(0, -1)
				}
		files_list = computed =>
			files.value if render_style.value == 'list'
		files_tree = computed =>
			return if render_style.value != 'tree'
			out =
				children: {}
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
			unify = (curr) =>
				for child_i, child of curr.children
					if ! child.files.length
						for grand_child from child.children
							grand_child.path = child.path + '/' + grand_child.path
							curr.children[grand_child.path] = grand_child
						delete curr.children[child_i]
					else
						unify(child)
			unify(out)
			out
		{
			files_list
			files_tree
			render_style
		}






