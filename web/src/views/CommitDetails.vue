<template>
	<div class="commit-details">
		<div class="row fill-h">
			<div class="left flex-1">
				<h2 :title="commit.subject" class="summary">
					{{ commit.subject }}
				</h2>
				<p class="body">
					{{ body }}
				</p>
				<template v-if="config_show_buttons">
					<div v-if="stash" class="stash">
						<h3>
							Stash:
						</h3>
						<div class="row gap-5 wrap">
							<git-action-button v-for="action of stash_actions" :git_action="action" />
						</div>
					</div>
					<div v-if="branch_tips.length" class="branch-tips">
						<ul>
							<li v-for="branch_tip of branch_tips">
								<ref-tip :commit="commit" :git_ref="branch_tip" />
								<div class="row gap-5 wrap">
									<git-action-button v-for="action of branch_actions(branch_tip)" :git_action="action" />
									<button class="show-branch btn gap-5" title="Show the log for this branch only. Revert with a simple click on the main refresh button." @click="show_branch(branch_tip)">
										<i class="codicon codicon-eye" />Show
									</button>
								</div>
							</li>
						</ul>
					</div>
					<div v-if="tags.length" class="tags">
						<ul v-for="tag, tag_i of tags">
							<li>
								<ref-tip :commit="commit" :git_ref="tag" />
								<pre>{{ tag_details[tag_i] }}</pre>
								<div class="row gap-5 wrap">
									<git-action-button v-for="action of tag_actions(tag.name)" :git_action="action" />
								</div>
							</li>
						</ul>
					</div>
					<div class="commit">
						<h3>
							This commit {{ commit.hash }}<button title="Jump to commit" @click="$emit('hash_clicked',commit.hash)">
								<i class="codicon codicon-link" />
							</button>:
						</h3>
						<div class="row gap-5 wrap">
							<git-action-button v-for="action of commit_actions" :git_action="action" />
						</div>
					</div>
				</template>
				<files-diffs-list v-if="details_panel_position !== 'bottom'" :files="changed_files" @show_diff="show_diff" @view_rev="view_rev" />
				<h3>
					Parent commits
				</h3>
				<ul>
					<li v-for="parent_hash of parent_hashes">
						{{ parent_hash }}
						<button title="Jump to commit" @click="$emit('hash_clicked',parent_hash)">
							<i class="codicon codicon-link" />
						</button>
					</li>
				</ul>
				<br>
				<details>
					<summary class="align-center">
						Compare...
					</summary>In order to compare this commit with another one, do <kbd>Ctrl/Cmd</kbd>+Click on any other commit in the main view
				</details>
				<h3>
					Details
				</h3>
				<p>
					Full hash: {{ commit.hash_long }}
				</p>
			</div>
			<div :class="details_panel_position === 'bottom' ? 'flex-1' : ''" class="right">
				<files-diffs-list v-if="details_panel_position === 'bottom'" :files="changed_files" @show_diff="show_diff" @view_rev="view_rev" />
			</div>
		</div>
	</div>
</template>
<script src="./CommitDetails"></script>
<style scoped>
h2.summary {
	white-space: pre-line;
	word-break: break-word;
	overflow: hidden;
	text-overflow: ellipsis;
}
.body {
	white-space: pre-wrap;
	word-break: break-word;
}
.branch-tips .ref-tip,
.tags .ref-tip {
	margin: 20px 10px 10px;
}
.left,
.right {
	overflow: auto;
}
</style>
