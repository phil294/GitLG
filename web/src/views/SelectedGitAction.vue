<template>
	<div class="selected-git-action">
		<h2>
			<template v-if="selected_git_action.title">
				{{ selected_git_action.title }} -&nbsp;
			</template>{{ selected_git_action.description }}
		</h2>
		<details v-if="selected_git_action.info" class="padding">
			<summary>
				{{ selected_git_action.info }}
			</summary>{{ selected_git_action.info }}
		</details>
		<git-input :git_action="selected_git_action" @executed="refresh_main_view()" @success="success()" />
		<br>
		<label class="row align-center gap-5">
			<input v-model="keep_open" type="checkbox">Keep window open after success</label>
	</div>
</template>
<script src="./SelectedGitAction"></script>
<style>
.selected-git-action {
	width: clamp(200px, 50vw, 50vw);
}
.selected-git-action > details {
	white-space: pre-line;
}
.selected-git-action > details > summary {
	overflow: hidden;
	text-overflow: ellipsis;
	color: #808080;
}
</style>
