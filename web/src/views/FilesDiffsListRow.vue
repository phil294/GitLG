<template lang="slm">
.files-diffs-list-row.row
	button.change.center.gap-5 @click="$emit('show_diff',file.path)" :title="file.insertions+' insertions, '+file.deletions+' deletions'"
		.count {{ (file.insertions + file.deletions) || 0 }}
		progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0"
		.filename {{ file.filename }}
	div.btns.row
		button.view-rev @click="$emit('view_rev',file.path)" title="View File at this Revision"
			i.codicon.codicon-git-commit
		button.open-file @click="open_file(file.path)" title="Open file"
			i.codicon.codicon-go-to-file
</template>

<script lang="coffee" src="./FilesDiffsListRow.coffee"></script>

<style lang="stylus" scoped>
.files-diffs-list-row
	.change
		font-family monospace
		font-size 90%
		> .count
			text-align right
			width 2rem
		> .filename
			white-space pre
	.btns
		margin-left 0.5rem
		opacity 0
		button
			.open-file, .view-rev
				font-size 90%
	&:hover .btns
		opacity 1
</style>