<template>
	<div id="vue-app">
		<main-view />
	</div>
</template>
<script>
import * as store from './state/store.js'

store.init()
</script>

<style>
:root {
	--container-padding: 20px;
	--input-padding-vertical: 6px;
	--input-padding-horizontal: 4px;
	--input-margin-vertical: 4px;
	--input-margin-horizontal: 0;
}
body {
	color: #ccc;
	font-size: var(--vscode-font-size);
	font-weight: var(--vscode-font-weight);
	font-family: var(--vscode-font-family);
	background-color: #161616;
}
body.vscode-light,
body.vscode-high-contrast-light {
	background-color: var(--vscode-editor-background);
	filter: invert(1) hue-rotate(180deg);
}
ol,
ul,
*[role=list] {
	list-style: none;
	margin: 0;
	padding: 0;
}
*:focus {
	outline-color: var(--vscode-focusBorder) !important;
}
a {
	color: var(--vscode-textLink-foreground);
}
a:hover,
a:active {
	color: var(--vscode-textLink-activeForeground);
}
code {
	font-family: var(--vscode-editor-font-family);
	color: #ccc;
}
details {
	overflow: auto;
}
details > summary {
	cursor: pointer;
	list-style-type: none;
	height: 100%;
}
details > summary::before {
	font: 16px/1 codicon;
	user-select: none;
	height: 100%;
	padding-right: 6px;
	vertical-align: middle;
	display: inline-block;
	content: '\eab6';
}
details[open] > summary {
	height: unset;
}
details[open] > summary::before {
	content: '\eab4';
}
input:not([type='checkbox']):not([type='radio']),
textarea {
	display: block;
	border: none;
	font-family: monospace;
	font-size: 11.5px;
	padding: var(--input-padding-vertical) var(--input-padding-horizontal);
	color: var(--vscode-input-foreground);
	outline-color: var(--vscode-input-border);
	background-color: var(--vscode-input-background);
}
input::placeholder,
textarea::placeholder {
	color: var(--vscode-input-placeholderForeground);
}
select {
	color: #ccc;
	background: #161616;
	border-color: #333;
}
body,
html {
	margin: 0;
	padding: 0;
}
* {
	box-sizing: border-box;
}
.flex,
.col,
.row,
.justify-center,
.align-center,
.center {
	display: flex;
	min-height: 0;
	min-width: 0;
}
.flex-1 {
	flex: 1;
}
.flex-noshrink {
	flex-shrink: 0;
}
.wrap {
	flex-wrap: wrap;
}
.col {
	flex-direction: column;
}
.row {
	flex-direction: row;
}
.justify-center,
.center {
	justify-content: safe center;
}
.align-center,
.center {
	align-items: safe center;
}
.justify-flex-end {
	justify-content: flex-end;
}
.justify-space-between {
	justify-content: space-between;
}
.fill-w,
.fill {
	width: 100%;
}
.fill-h,
.fill {
	height: 100%;
}
.gap-3 {
	gap: 3px;
}
.gap-5 {
	gap: 5px;
}
.gap-10 {
	gap: 10px;
}
.col-gap-10 {
	column-gap: 10px;
}
.gap-20 {
	gap: 20px;
}
.padding {
	padding: 0.5vmax;
}
.padding-l {
	padding: 1vh 1vw;
}
.padding-xl {
	padding: 3vmax;
}
.error {
	color: #8b0000;
}
.warn {
	color: #ffa500;
}
.grey {
	color: #808080;
}
button {
	appearance: none;
	background: initial;
	border: initial;
	padding: initial;
	text-align: initial;
	font: inherit;
	color: inherit;
	user-select: none;
	cursor: pointer;
	color: #e5b567;
}
*[role=button] {
	cursor: pointer;
}
.btn,
input[type="submit"],
input[type="reset"],
input[type="button"] {
	display: inline-flex;
	align-items: center;
	white-space: pre;
	height: 24px;
	line-height: 24px;
	padding: 3px 5px;
	text-decoration: none;
	color: var(--vscode-button-foreground);
	background: var(--vscode-button-background);
	border: 1px solid var(--vscode-button-background);
}
.btn:enabled:hover,
input[type="submit"]:enabled:hover,
input[type="reset"]:enabled:hover,
input[type="button"]:enabled:hover {
	background: var(--vscode-button-hoverBackground);
	border-color: var(--vscode-button-hoverBackground);
	outline: 0;
}
.btn:enabled:active,
input[type="submit"]:enabled:active,
input[type="reset"]:enabled:active,
input[type="button"]:enabled:active {
	opacity: 0.7;
	border-width: 3px 0 0 2px;
}
.btn:disabled,
input[type="submit"]:disabled,
input[type="reset"]:disabled,
input[type="button"]:disabled {
	color: #808080;
	pointer-events: auto;
}
.btn.btn-2 {
	color: var(--vscode-button-secondaryForeground);
	background: var(--vscode-button-secondaryBackground);
}
.btn.btn-2:hover {
	background: var(--vscode-button-secondaryHoverBackground);
}
.btn-icon {
	padding-inline: 5px;
}
.btn-icon > vscode-icon {
	display: inline;
}
progress.diff {
	width: 30px;
	height: 3px;
	color: #090;
	background-color: #8b0000;
}
progress.diff::-webkit-progress-bar {
	background-color: #8b0000;
}
progress.diff::-webkit-progress-value {
	background-color: #090;
}
details > summary {
	white-space: nowrap;
}
input:not([type='checkbox']):not([type='radio']).filter {
	font-family: monospace;
	padding: 0 0 0 5px;
	background: #000;
	color: #d5983d;
}
ul.context-menu-wrapper {
	position: absolute;
	background: rgba(17,17,17,0.867);
	min-width: 150px;
	cursor: pointer;
	box-shadow: 0 2px 3px 2px rgba(17,17,17,0.867);
	user-select: none;
	z-index: 10;
}
ul.context-menu-wrapper > li {
	padding: 4px 8px;
}
ul.context-menu-wrapper > li:not(:last-child) {
	border-bottom: 1px solid #424242;
}
ul.context-menu-wrapper > li:hover {
	background: #000;
}
</style>

<style scoped>
#vue-app {
	height: 100vh;
	width: 100vw;
}
.error {
	background: #ffffe0;
}
</style>
