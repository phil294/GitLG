<template>
	<div v-context-menu="context_menu_provider" v-drag="drag" v-drop="drop" class="ref-tip" v-bind="bind">
		{{ git_ref.id }}
	</div>
</template>
<script src="./RefTip"></script>
<style scoped>
.ref-tip {
	background: #000;
	font-weight: bold;
	font-style: italic;
	display: inline-block;
	padding: 1px 3px;
	border: 1px solid #505050;
	border-radius: 7px;
	white-space: pre;
	margin: 0 1px;
}
.ref-tip.head {
	box-shadow: 0px 0px 6px 4px rgba(255,255,255,0.188), 0px 0px 4px 0px rgba(255,255,255,0.188) inset;
}
.ref-tip.head:after {
	content: ' (HEAD)';
	color: #fff;
}
.ref-tip.branch {
	cursor: move;
}
.ref-tip.branch.inferred {
	background: rgba(0,0,0,0.569);
	opacity: 0.7;
	font-weight: normal;
}
.ref-tip.branch.inferred:hover {
	opacity: unset;
	font-weight: bold;
	background: #000;
}
.ref-tip.branch.dragenter {
	background: #fff !important;
	color: #f00 !important;
}
</style>
