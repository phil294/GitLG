<template>
	<div id="repo-selection">
		<select v-if="repo_infos?.length > 1 || ! selected_repo_path_is_valid" v-model="selected_repo_path" :class="{invalid: !selected_repo_path_is_valid}" :aria-invalid="!selected_repo_path_is_valid">
			<option v-for="repo_info of repo_infos" :key="repo_info.name" :value="repo_info.path">
				{{ repo_info.name }}
			</option>
		</select>
	</div>
</template>
<script setup>
import { repo_infos, selected_repo_path, selected_repo_path_is_valid } from '../../data/store'
</script>
<style scoped>
select.invalid {
	border: 1px solid var(--vscode-inputValidation-errorBorder);
}
</style>
