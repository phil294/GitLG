<template lang="slm">
/ TODO rename to filesdiffs, incl class
.files-diffs-list
	h3 Changes

	aside.actions
		button v-if="render_style==='tree'" @click="render_style='list'" title="View as list"
			i.codicon.codicon-list-tree
		button v-else="" @click="render_style='tree'" title="View as tree"
			i.codicon.codicon-list-flat

	template-file-change-define v-slot="{ file }"
		button.change.center.gap-10 :title="file.insertions+' insertions, '+file.deletions+' deletions'"
			progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0"
			.count {{ (file.insertions + file.deletions) || 0 }}

	template-file-actions-define v-slot="{ file }"
		.file-actions.row.align-center
			button.row.view-rev @click.stop="mark_file_viewed(file), $emit('view_rev',file.path2)" title="View File at this Revision"
				i.codicon.codicon-git-commit
			button.row.open-file @click.stop="mark_file_viewed(file), open_file(file, file.path2)" title="Open file"
				i.codicon.codicon-go-to-file

	ul.list v-if="files_list"
		li.list-row.flex-1.row.align-center.gap-10 v-for="file of files_list" @click="mark_file_viewed(file), $emit('show_diff', file.path1, file.path2)" role="button"
			.flex-1.fill-h.row.align-center.gap-10
				img :src="file.icon_path" aria-hidden="true"
				div :class="{ 'walkthrough-not-viewed': !walkthrough_file_view_map[file.path2], filename: true  }" :title="file.file_desc"
					div {{ file.filename1 }}
					div v-if="file.path1 !== file.path2"
						| => {{ file.path2 }}
				.dir :title="file.dir" {{ file.dir }}
			template-file-actions-reuse :file="file"
			template-file-change-reuse :file="file"

	template-tree-node-define v-slot="{ node }"
		details.tree-node open=""
			summary :title="node.path"
				| {{ node.path }}
			.body
				template-tree-node-reuse v-for="child of node.children" :node="child"
				template v-for="file of node.files"
					button.fill-w.row.align-center.gap-10 @click="mark_file_viewed(file), $emit('show_diff', file.path1, file.path2)"
						img :src="file.icon_path" aria-hidden="true"
						div :class="{ 'walkthrough-not-viewed': !walkthrough_file_view_map[file.path2], filename: true, 'flex-1': true }" :title="file.file_desc"
							div {{ file.filename1 }}
							div v-if="file.path1 !== file.path2"
								| => {{ file.path2 }}
						template-file-actions-reuse :file="file"
						template-file-change-reuse :file="file"
	.tree v-if="files_tree"
		template-tree-node-reuse :node="files_tree"
</template>

<script lang="coffee" src="./FilesDiffsList.coffee"></script>

<style lang="stylus" scoped>
.files-diffs-list
	position relative
	.change
		flex-shrink 0
		font-family monospace
		font-size 90%
		> .count
			width 2rem
	.filename
		white-space pre
		overflow hidden
		text-overflow ellipsis
		color #E5B567
		flex-shrink 0
	ul.list > li
		padding-left 10px
		position relative
		.dir
			font-size .9em
			opacity .7
			white-space pre
			overflow hidden
			text-overflow ellipsis
	.tree-node
		position relative
	aside.actions
		opacity 0
		position absolute
		top 0
		right 0
	&:hover
		aside.actions
			opacity 1
	.file-actions
		display none
	.list-row, .tree-node > summary, .tree-node > .body > .row
		img
			height 20px
		.walkthrough-not-viewed
			font-weight bold
		&:hover
			background #2a2d2e
			> .file-actions
				display flex
	.tree-node > .body
		padding-left 20px
</style>