<template lang="slm">
/ TODO rename to filesdiffs, incl class
.files-diffs-list
	ul.list v-if="files_list"
		li.flex-1.row.gap-10.align-center v-for="file of files_list"
			files-diffs-list-row :file="file"
			.dir {{ file.dir }}
	files-diffs-tree-node.tree v-else-if="files_tree" :node="files_tree"
	aside
		button @click="render_style=render_style==='list'?'tree':'list'" title="Toggle view as list / tree"
			i.codicon.codicon-tree v-if="render_style==='tree'"
			i.codicon.codicon-list v-else=""
</template>

<script lang="coffee" src="./FilesDiffsList.coffee"></script>

<style lang="stylus" scoped>
ul.list
	padding 0
	> li
		> .dir
			white-space pre
			color #aaa
</style>