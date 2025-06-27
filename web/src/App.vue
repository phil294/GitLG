<template>
	<div id="vue-app">
		<main-view />
	</div>
</template>
<script>
import './data/store'
</script>

<style>
:root {
	--container-padding: 12px;
	--input-padding-vertical: 6px;
	--input-padding-horizontal: 4px;
	--input-margin-vertical: 4px;
	--input-margin-horizontal: 0;
	--text-secondary: rgb(from var(--vscode-editor-foreground) r g b / 0.7);
}
body,
input,
textarea,
select {
	font-size: var(--vscode-font-size);
	font-weight: var(--vscode-font-weight);
	font-family: var(--vscode-font-family);
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
	padding: 2px 6px;
}
details {
	overflow: auto;
}
details > summary {
	cursor: pointer;
	list-style-type: none;
	height: 100%;
	white-space: nowrap;
	display: flex;
	align-items: center;
}
details > summary::before {
	font: 16px/1 codicon;
	user-select: none;
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
input:not([type='checkbox']):not([type='radio']):not([type='submit']):not([type='range']),
textarea {
	display: block;
	border: none;
	padding: var(--input-padding-vertical) var(--input-padding-horizontal);
	color: var(--vscode-input-foreground);
	outline-color: var(--vscode-input-border);
	background-color: var(--vscode-input-background);
	border-radius: 2px;
	border: 1px solid var(--vscode-settings-textInputBorder, var(--vscode-input-background));
    line-height: 18px;
    padding: 3px 4px;
}
input::placeholder,
textarea::placeholder {
	color: var(--vscode-input-placeholderForeground);
}
select {
    background-color: var(--vscode-settings-dropdownBackground);
    border: 1px solid var(--vscode-settings-dropdownBorder);
    border-radius: 2px;
    color: var(--vscode-settings-dropdownForeground);
    line-height: 18px;
	padding: 3px 4px;
}
[inert] {
	filter: grayscale() opacity(0.6)
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
	padding: 12px;
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
	color: var(--text-secondary) !important;
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
	white-space: pre-line;
	line-height: 22px;
	padding: 1px 13px;
	text-decoration: none;
	color: var(--vscode-button-foreground);
	background: var(--vscode-button-background);
	border: 1px solid var(--vscode-button-border, var(--vscode-button-background));
    border-radius: 2px;
}
/* TODO: ::highlight not supported on FF. exp flag in bin build? */
.highlighted, .highlighted i.codicon, ::highlight(search) {
	color: var(--vscode-inputOption-activeForeground) !important;
}
.highlighted, ::highlight(search) {
	background-color: var(--vscode-inputOption-activeBackground, orange) !important;
	border: 1px solid var(--vscode-inputOption-activeBorder) !important; /* ignored by ::highlight */
	border-radius: 3px !important; /* ignored by ::highlight */
}
.vscode-high-contrast, .vscode-high-contrast-light {
	.highlighted, ::highlight(search) {
		text-decoration: underline !important;
	}
}
button:not(.btn) i.codicon {
	color: var(--vscode-icon-foreground);
}
input[type="checkbox"] {
	height: 26px;
	width: 0px;
	margin: 0 27px 0 0;
	position: relative;
	&:after {
		content: '';
		position: absolute;
		height: 18px;
		width: 18px;
		top: 4px;
		border-radius: 3px;
		box-sizing: border-box;
		background-color: var(--vscode-settings-checkboxBackground);
		border: 1px solid var(--vscode-settings-checkboxBorder);
	}
	&:focus:after {
		outline: 1px solid var(--vscode-focusBorder);
	}
	&:checked:after {
		/* fill=currentColor doesn't work here... */
		background-image: url('data:image/svg+xml;utf8,<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill="white"><path fill-rule="evenodd" clip-rule="evenodd" d="M14.431 3.323l-8.47 10-.79-.036-3.35-4.77.818-.574 2.978 4.24 8.051-9.506.764.646z"></path></svg>');
	}
	/* ...so apparently the only solution is to make a second one with fixed color too which should look fine for most themes */
	.vscode-light &, .vscode-high-contrast-light & {
		&:checked:after {
			background-image: url('data:image/svg+xml;utf8,<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill="black"><path fill-rule="evenodd" clip-rule="evenodd" d="M14.431 3.323l-8.47 10-.79-.036-3.35-4.77.818-.574 2.978 4.24 8.051-9.506.764.646z"></path></svg>');
		}
	}
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
	color: var(--text-secondary);
	pointer-events: auto;
}
.btn.btn-2 {
	color: var(--vscode-button-secondaryForeground);
	background: var(--vscode-button-secondaryBackground);
}
.btn.btn-2:hover {
	background: var(--vscode-button-secondaryHoverBackground);
}
progress.diff {
	width: 30px;
	height: 3px;
	opacity: 0.8;
	color: lime;
	background-color: red;
}
progress.diff::-webkit-progress-bar {
	background-color: #8b0000;
}
progress.diff::-webkit-progress-value {
	background-color: #090;
}
ul.context-menu-wrapper {
	position: absolute;
	background: var(--vscode-menu-background);
	color: var(--vscode-menu-foreground);
	font-size: 12px;
	border-radius: 4px;
	border: 1px solid var(--vscode-menu-border);
	cursor: pointer;
	box-shadow: 0 2px 8px var(--vscode-widget-shadow);
	padding: 4px 0;
	user-select: none;
	z-index: 10;
}
ul.context-menu-wrapper > li {
	line-height: 1.4em;
	height: 2em;
	margin: 0 4px;
	padding: 0 22px 0 4px;
	border-radius: 3px;
	user-select: none;
	white-space: nowrap;
}
ul.context-menu-wrapper > li:hover, ul.context-menu-wrapper > li.selected {
	background-color: var(--vscode-menu-selectionBackground, var(--vscode-menu-background));
	color: var(--vscode-menu-selectionForeground, var(--vscode-menu-foreground));
	outline: 1px solid var(--vscode-menu-selectionBorder, var(--vscode-menu-selectionBackground));
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
