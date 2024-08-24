<template>
	<div id="all-branches">
		<details id="show-all-branches" ref="details_ref" class="center">
			<summary>
				All branches...
			</summary>
			<div class="dv">
				<input v-model="txt_filter" class="filter" placeholder="🔍 filter branch name">
				<div class="branches">
					<button v-for="branch of filtered_branches" title="Jump to branch tip" @click="$emit('branch_selected',branch);show_all_branches=false">
						<ref-tip :git_ref="branch" />
					</button>
				</div>
			</div>
		</details>
	</div>
</template>
<script src="./AllBranches"></script>
<style scoped>
details#show-all-branches > summary {
	display: flex;
	align-items: center;
	justify-content: end;
}
.dv {
	padding: 5px 10px 20px 20px;
}
.dv > button > .ref-tip.branch {
	margin: 2px;
	padding: 1px 6px;
}
input.filter {
	margin: 5px;
	float: right;
	width: unset !important;
}
</style>
