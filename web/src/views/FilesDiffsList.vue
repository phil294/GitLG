<template lang="slm">
ul.files-diffs-list
	li.row v-for="file of files"
		button.change.center.gap-5 @click="$emit('show_diff',file.path)" :title="file.insertions+' insertions, '+file.deletions+' deletions'"
			.count {{ (file.insertions + file.deletions) || 0 }}
			progress.diff :value="(file.insertions / (file.insertions + file.deletions)) || 0"
			.path.flex-1.row.gap-10.align-center
				.filename {{ file.filename }}
				.dir {{ file.dir }}
		div.btns.row
			button.view-rev @click="$emit('view_rev',file.path)" title="View File at this Revision"
				i.codicon.codicon-git-commit
			button.open-file @click="open_file(file.path)" title="Open file"
				i.codicon.codicon-go-to-file

</template>

<script lang="coffee" src="./FilesDiffsList.coffee"></script>

<style lang="stylus" scoped>
.files-diffs-list
	padding 0
	overflow auto
	.row
		.change
			font-family monospace
			font-size 90%
			> .count
				text-align right
				width 2rem
			> .path
				white-space pre
				> .dir
					color #aaa
		.btns
			margin-left 0.5rem
			opacity 0
			button
				.open-file, .view-rev
					font-size 90%
		&:hover .btns
				opacity 1
</style>