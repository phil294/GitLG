<template>
	<div id="repo-selection">
		<select v-model="selection">
			<option v-for="repo_name, i of repo_names" :value="i">
				{{ repo_name }}
			</option>
		</select>
	</div>
</template>
<script src="./RepoSelection"></script>
<style>

</style>
