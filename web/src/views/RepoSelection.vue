<template>
	<div id="repo-selection">
		<select v-if="repo_infos?.length > 1" v-model="selected_repo_path">
			<option v-for="repo_info of repo_infos" :key="repo_info.name" :value="repo_info.path">
				{{ repo_info.name }}
			</option>
		</select>
	</div>
</template>
<script setup>
import { repo_infos, selected_repo_path } from '../data/store.js'
</script>
