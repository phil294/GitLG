
	// DO NOT EDIT - AUTO GENERATED FROM vite.config.js

	// This file solely exists to enable type support in Vue VSCode extension
	// https://stackoverflow.com/a/70980761/3779853

	import { HTMLAttributes } from 'vue'
	import { RecycleScroller } from 'vue-virtual-scroller'
	import App from './App.vue'
	import AllBranches from './views/AllBranches.vue'
	import CommitDetails from './views/CommitDetails.vue'
	import CommitFileChanges from './views/CommitFileChanges.vue'
	import CommitRefTips from './views/CommitRefTips.vue'
	import CommitRow from './views/CommitRow.vue'
	import CommitsDetails from './views/CommitsDetails.vue'
	import GitActionButton from './views/GitActionButton.vue'
	import GitInput from './views/GitInput.vue'
	import History from './views/History.vue'
	import MainView from './views/MainView.vue'
	import RefTip from './views/RefTip.vue'
	import RepoSelection from './views/RepoSelection.vue'
	import SVGVisualization from './views/SVGVisualization.vue'
	import SelectedGitAction from './views/SelectedGitAction.vue'
	import Popup from './components/Popup.vue'
	import PromiseForm from './components/PromiseForm.vue'
	import {VscodeBadge, VscodeButton, VscodeCheckbox, VscodeCheckboxVscodeGroup, VscodeCollapsible, VscodeContextVscodeMenu, VscodeContextVscodeMenuVscodeItem, VscodeDivider, VscodeFormVscodeContainer, VscodeFormVscodeGroup, VscodeFormVscodeHelper, VscodeIcon, VscodeLabel, VscodeMultiVscodeSelect, VscodeOption, VscodeProgressVscodeRing, VscodeRadio, VscodeRadioVscodeGroup, VscodeScrollable, VscodeSingleVscodeSelect, VscodeSplitVscodeLayout, VscodeTabVscodeHeader, VscodeTabVscodePanel, VscodeTable, VscodeTableVscodeBody, VscodeTableVscodeCell, VscodeTableVscodeHeader, VscodeTableVscodeHeaderVscodeCell, VscodeTableVscodeRow, VscodeTabs, VscodeTextarea, VscodeTextfield, VscodeTree} from '@vscode-elements/elements'

	declare module '@vue/runtime-core' {
		
		
		type ClassToComponent<C> = DefineComponent<{}, { $props: Partial<C> & { modelValue?: any } & HTMLAttributes }>
		export interface GlobalComponents {
			RecycleScroller: typeof RecycleScroller
			App: typeof App
			AllBranches: typeof AllBranches
			CommitDetails: typeof CommitDetails
			CommitFileChanges: typeof CommitFileChanges
			CommitRefTips: typeof CommitRefTips
			CommitRow: typeof CommitRow
			CommitsDetails: typeof CommitsDetails
			GitActionButton: typeof GitActionButton
			GitInput: typeof GitInput
			History: typeof History
			MainView: typeof MainView
			RefTip: typeof RefTip
			RepoSelection: typeof RepoSelection
			SVGVisualization: typeof SVGVisualization
			SelectedGitAction: typeof SelectedGitAction
			Popup: typeof Popup
			PromiseForm: typeof PromiseForm
			VscodeBadge: ClassToComponent<VscodeBadge>
			VscodeButton: ClassToComponent<VscodeButton>
			VscodeCheckbox: ClassToComponent<VscodeCheckbox>
			VscodeCheckboxVscodeGroup: ClassToComponent<VscodeCheckboxVscodeGroup>
			VscodeCollapsible: ClassToComponent<VscodeCollapsible>
			VscodeContextVscodeMenu: ClassToComponent<VscodeContextVscodeMenu>
			VscodeContextVscodeMenuVscodeItem: ClassToComponent<VscodeContextVscodeMenuVscodeItem>
			VscodeDivider: ClassToComponent<VscodeDivider>
			VscodeFormVscodeContainer: ClassToComponent<VscodeFormVscodeContainer>
			VscodeFormVscodeGroup: ClassToComponent<VscodeFormVscodeGroup>
			VscodeFormVscodeHelper: ClassToComponent<VscodeFormVscodeHelper>
			VscodeIcon: ClassToComponent<VscodeIcon>
			VscodeLabel: ClassToComponent<VscodeLabel>
			VscodeMultiVscodeSelect: ClassToComponent<VscodeMultiVscodeSelect>
			VscodeOption: ClassToComponent<VscodeOption>
			VscodeProgressVscodeRing: ClassToComponent<VscodeProgressVscodeRing>
			VscodeRadio: ClassToComponent<VscodeRadio>
			VscodeRadioVscodeGroup: ClassToComponent<VscodeRadioVscodeGroup>
			VscodeScrollable: ClassToComponent<VscodeScrollable>
			VscodeSingleVscodeSelect: ClassToComponent<VscodeSingleVscodeSelect>
			VscodeSplitVscodeLayout: ClassToComponent<VscodeSplitVscodeLayout>
			VscodeTabVscodeHeader: ClassToComponent<VscodeTabVscodeHeader>
			VscodeTabVscodePanel: ClassToComponent<VscodeTabVscodePanel>
			VscodeTable: ClassToComponent<VscodeTable>
			VscodeTableVscodeBody: ClassToComponent<VscodeTableVscodeBody>
			VscodeTableVscodeCell: ClassToComponent<VscodeTableVscodeCell>
			VscodeTableVscodeHeader: ClassToComponent<VscodeTableVscodeHeader>
			VscodeTableVscodeHeaderVscodeCell: ClassToComponent<VscodeTableVscodeHeaderVscodeCell>
			VscodeTableVscodeRow: ClassToComponent<VscodeTableVscodeRow>
			VscodeTabs: ClassToComponent<VscodeTabs>
			VscodeTextarea: ClassToComponent<VscodeTextarea>
			VscodeTextfield: ClassToComponent<VscodeTextfield>
			VscodeTree: ClassToComponent<VscodeTree>
		}
	}