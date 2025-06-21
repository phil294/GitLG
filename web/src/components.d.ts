
	// DO NOT EDIT - AUTO GENERATED FROM vite.config.js

	// This file solely exists to enable type support in Vue VSCode extension
	// https://stackoverflow.com/a/70980761/3779853

	import { HTMLAttributes } from 'vue'
	import { RecycleScroller } from 'vue-virtual-scroller'
	import App from './App.vue'
	import AllBranches from './views/main-view/AllBranches.vue'
	import CommitDetails from './views/main-view/CommitDetails.vue'
	import CommitsDetails from './views/main-view/CommitsDetails.vue'
	import History from './views/main-view/History.vue'
	import MainView from './views/main-view/MainView.vue'
	import RepoSelection from './views/main-view/RepoSelection.vue'
	import SearchInput from './views/main-view/SearchInput.vue'
	import SelectedGitAction from './views/main-view/SelectedGitAction.vue'
	import CommitRow from './views/main-view/scroller/CommitRow.vue'
	import SVGVisualization from './views/main-view/scroller/SVGVisualization.vue'
	import Scroller from './views/main-view/scroller/Scroller.vue'
	import CommitDiff from './components/CommitDiff.vue'
	import CommitRefTips from './components/CommitRefTips.vue'
	import GitActionButton from './components/GitActionButton.vue'
	import GitInput from './components/GitInput.vue'
	import Popup from './components/Popup.vue'
	import PromiseForm from './components/PromiseForm.vue'
	import RefTip from './components/RefTip.vue'

	declare module '@vue/runtime-core' {
		export interface GlobalComponents {
			RecycleScroller: typeof RecycleScroller
			App: typeof App
			AllBranches: typeof AllBranches
			CommitDetails: typeof CommitDetails
			CommitsDetails: typeof CommitsDetails
			History: typeof History
			MainView: typeof MainView
			RepoSelection: typeof RepoSelection
			SearchInput: typeof SearchInput
			SelectedGitAction: typeof SelectedGitAction
			CommitRow: typeof CommitRow
			SVGVisualization: typeof SVGVisualization
			Scroller: typeof Scroller
			CommitDiff: typeof CommitDiff
			CommitRefTips: typeof CommitRefTips
			GitActionButton: typeof GitActionButton
			GitInput: typeof GitInput
			Popup: typeof Popup
			PromiseForm: typeof PromiseForm
			RefTip: typeof RefTip
		}
	}