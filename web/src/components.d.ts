
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
	import SearchInput from './views/SearchInput.vue'
	import SelectedGitAction from './views/SelectedGitAction.vue'
	import Popup from './components/Popup.vue'
	import PromiseForm from './components/PromiseForm.vue'

	declare module '@vue/runtime-core' {
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
			SearchInput: typeof SearchInput
			SelectedGitAction: typeof SelectedGitAction
			Popup: typeof Popup
			PromiseForm: typeof PromiseForm
		}
	}