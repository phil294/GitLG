import { ref, computed, defineComponent, watchEffect } from 'vue'
import { git, exchange_message } from '../bridge.coffee'
import { commits_actions } from './store.coffee'
import GitActionButton from './GitActionButton.vue'
import FilesDiffsList from './FilesDiffsList.vue'
``###*
# @typedef {import('./types').Commit} Commit
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###
###* @template T @typedef {import('vue').ComputedRef<T>} ComputedRef ###

export default defineComponent
	components: { GitActionButton, FilesDiffsList }
	emits: ['hash_clicked']
	props:
		commits:
			###* @type {() => Commit[]} ###
			type: Object
			required: true
	setup: (props) ->
		``###* @type {Ref<{path:string,insertions:number,deletions:number}[]>} ###
		comparison_files = ref []
		merge_bases = ref []
		watchEffect =>
			return if props.commits.length != 2
			get_files_command = "diff --numstat --format=\"\" #{props.commits[0].full_hash} #{props.commits[1].full_hash}"
			comparison_files.value = (try await git get_files_command)
				# TODO externalize? subcomponent?
				?.split('\n').filter((l) => l && !!l.trim()).map((l) =>
					split = l.split('\t')
					path: split[2]
					insertions: Number split[1]
					deletions: Number split[0]) or []
			get_merge_base_command = "merge-base --all #{props.commits[0].full_hash} #{props.commits[1].full_hash}"
			merge_bases.value = (try await git get_merge_base_command)
				?.split('\n') or []

		show_compare_diff = (###* @type string ### filepath1, ###* @type string ### filepath2) =>
			exchange_message 'open-diff',
				hashes: [props.commits[0].full_hash, props.commits[1].full_hash]
				filepath1: filepath1
				filepath2: filepath2
		view_rev = (###* @type string ### filepath) =>
			exchange_message 'view-rev',
				hash: props.commits[1].full_hash
				filename: filepath

		_commits_actions = computed =>
			commits_actions(props.commits.map((c)=>c.full_hash)).value

		{
			comparison_files
			merge_bases
			show_compare_diff
			view_rev
			commits_actions: _commits_actions
		}