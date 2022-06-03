import { git, open_diff } from '../store.coffee'
import { Commit } from '../log-utils.coffee'
import { ref, Ref, computed, defineComponent, watchEffect } from 'vue'
import GitInput from './GitInput.vue'

config_branch_actions = [
	title: "→   Checkout"
	immediate: true
	args: 'checkout $1'
	params: [ "{BRANCH_NAME}" ]
,
	title: "⛙   Merge"
	args: 'merge $1'
	params: [ "{BRANCH_NAME}" ]
	options: [ value: '--no-commit', default_active: false ]
,
	title: "✎   Rename"
	args: 'branch -m $1 $2'
	params: [ "{BRANCH_NAME}" , 'new_branch_name' ]
,
	title: "🗑   Delete"
	args: 'branch -d $1'
	params: [ "{BRANCH_NAME}" ]
	options: [ value: '--force', default_active: false ]
]

config_commit_actions = [
	title: "→   Checkout"
	immediate: true
	args: 'checkout $1'
	params: [ "{COMMIT_HASH}" ]
,
	title: "+   Create branch"
	args: 'branch $1 $2'
	params: [ 'new_branch_name',  "{COMMIT_HASH}" ]
,
	title: "𖣣   Cherry pick"
	args: 'cherry-pick $1'
	params: [ "{COMMIT_HASH}" ]
	options: [ value: '--no-commit', default_active: false ]
,
	title: "⎌   Revert"
	args: 'revert $1'
	params: [ "{COMMIT_HASH}" ]
	options: [ value: '--no-commit', default_active: false ]
]

export default defineComponent
	components: { GitInput }
	emits: [ 'change' ]
	props:
		commit:
			###* @type {() => Commit} ###
			type: Object
			required: true
	setup: (props, { emit }) ->
		``###* @type {Ref<any>} ### # TODO import type from gitinput coffee somehow
		args = ref null
		
		branch_tips = computed =>
			props.commit.refs.filter (ref) =>
				ref.type == "branch"
		
		keep_open = ref false
		
		git_execute_success = =>
			if not keep_open.value
				args.value = null
				emit 'change' # todo this is actually independent of keep_open :/

		``###* @type {Ref<{path:string,insertions:number,deletions:number}[]>} ###
		changed_files = ref []
		body = ref ''
		watchEffect =>
			changed_files.value = (try await git "diff --numstat --format='' #{props.commit.hash} #{props.commit.hash}~1")
				?.split('\n').map((l) =>
					split = l.split('\t')
					path: split[2]
					insertions: Number split[1]
					deletions: Number split[0]) or []
			body.value = await git "show -s --format='%b' #{props.commit.hash}"
		
		show_diff = (###* @type string ### filepath) =>
			open_diff props.commit.hash, filepath
		
		commit_actions = config_commit_actions.map (a) => {
			...a
			params: a.params?.map (p) =>
				p.replaceAll('{COMMIT_HASH}', props.commit.hash)
		}

		branch_actions = (###* @type string ### branch_name) => config_branch_actions.map (a) => {
			...a
			params: a.params?.map (p) =>
				p.replaceAll('{BRANCH_NAME}', branch_name)
		}

		{
			args
			branch_tips
			git_execute_success
			keep_open
			changed_files
			show_diff
			body
			commit_actions
			branch_actions
		}