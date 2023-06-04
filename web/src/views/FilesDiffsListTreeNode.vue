<template lang="slm">
details.files-diffs-tree-node open=""
	summary
		{{ node.path }}
	files-diffs-list-tree-node v-for="child of node.children" :node="child"
	files-diffs-list-row v-for="file of node.files" :file="file"
</template>

<script lang="coffee" src="./FilesDiffsListTreeNode.coffee"></script>

<style lang="stylus" scoped>
</style>