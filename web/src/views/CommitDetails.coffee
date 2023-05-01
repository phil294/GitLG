import { ref, computed, defineComponent, watchEffect } from 'vue'
import { git, exchange_message } from '../bridge.coffee'
import { commit_actions, stash_actions, branch_actions, tag_actions } from './store.coffee'
import GitActionButton from './GitActionButton.vue'
import RefTip from './RefTip.vue'
``###*
# @typedef {import('./types').Commit} Commit
###
###* @template T @typedef {import('vue').Ref<T>} Ref ###
###* @template T @typedef {import('vue').ComputedRef<T>} ComputedRef ###

export default defineComponent
	components: { GitActionButton, RefTip }
	props:
		commit:
			###* @type {() => Commit} ###
			type: Object
			required: true
	setup: (props) ->
		branch_tips = computed =>
			props.commit.refs.filter (ref) =>
				ref.type == "branch"
		
		tags = computed =>
			props.commit.refs.filter (ref) =>
				ref.type == "tag"

		stash = computed =>
			props.commit.refs.find (ref) =>
				ref.type == "stash"
		
		``###* @type {Ref<{path:string,insertions:number,deletions:number}[]>} ###
		changed_files = ref []
		body = ref ''
		watchEffect =>
			get_files_command =
				if stash.value
					# so we can see untracked as well
					"stash show --include-untracked --numstat --format=\"\" #{props.commit.hash}"
				else
					"diff --numstat --format=\"\" #{props.commit.hash} #{props.commit.hash}~1"
			changed_files.value = (try await git get_files_command)
				?.split('\n').map((l) =>
					split = l.split('\t')
					path: split[2]
					insertions: Number split[1]
					deletions: Number split[0]) or []
			body.value = await git "show -s --format=\"%b\" #{props.commit.hash}"
		
		show_diff = (###* @type string ### filepath) =>
			exchange_message 'open-diff',
				hash: props.commit.hash
				filename: filepath
		
		_commit_actions = commit_actions(props.commit.hash)
		_stash_actions = stash_actions(props.commit.hash)

		{
			branch_tips
			tags
			stash
			changed_files
			show_diff
			body
			commit_actions: _commit_actions
			branch_actions
			tag_actions
			stash_actions: _stash_actions
		}