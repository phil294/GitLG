<template lang="slm">
.commit-details
	h2.summary :title="commit.subject" {{ commit.subject }}

	p.body {{ body }}

	template v-if="config_show_buttons"
		.stash v-if="stash"
			h3 Stash:
			.row.gap-5.wrap
				git-action-button v-for="action of stash_actions" :git_action="action"

		.branch-tips v-if="branch_tips.length"
			ul
				li v-for="branch_tip of branch_tips"
					ref-tip :git_ref="branch_tip" :commit="commit"
					.row.gap-5.wrap
						git-action-button v-for="action of branch_actions(branch_tip)" :git_action="action"
						button.show-branch.btn.gap-5 @click="show_branch(branch_tip)" title="Show the log for this branch only. Revert with a simple click on the main refresh button."
							i.codicon.codicon-eye
							| Show

		.tags v-if="tags.length"
			ul v-for="tag, tag_i of tags"
				li
					ref-tip :git_ref="tag" :commit="commit"
					pre {{ tag_details[tag_i] }}
					.row.gap-5.wrap
						git-action-button v-for="action of tag_actions(tag.name)" :git_action="action"

		.commit
			h3
				| This commit {{ commit.hash }}
				button @click="$emit('hash_clicked',commit.hash)" title="Jump to commit"
					i.codicon.codicon-link
				| :
			.row.gap-5.wrap
				git-action-button v-for="action of commit_actions" :git_action="action"

	files-diffs-list :files="changed_files" @show_diff="show_diff" @view_rev="view_rev"

	h3 Parent commits
	ul
		li v-for="parent_hash of parent_hashes"
			| {{ parent_hash }}
			button @click="$emit('hash_clicked',parent_hash)" title="Jump to commit"
				i.codicon.codicon-link

	br
	details
		summary.align-center Compare...
		| In order to compare this commit with another one, do <kbd>Ctrl</kbd>+Click on any other commit in the main view

	h3 Details
	p Full hash: {{ commit.hash_long }}
</template>

<script lang="coffee" src="./CommitDetails.coffee"></script>

<style lang="stylus" scoped>
h2.summary
	white-space pre-line
	word-break break-word
	overflow hidden
	text-overflow ellipsis
.body
	white-space pre-wrap
	word-break break-word
.branch-tips, .tags
	.ref-tip
		margin 20px 10px 10px
</style>