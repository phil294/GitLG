import { git, open_diff } from '../store.coffee'
import { Commit } from '../log-utils.coffee'
import { ref, Ref, computed, defineComponent, watchEffect } from 'vue'
import GitPopup from './GitPopup.vue'

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

config_stash_actions = [
	title: "→   Apply"
	immediate: true
	args: 'checkout $1'
	params: [ "{COMMIT_HASH}" ]
]

## TODO externalize
export parse_config_actions = (actions, ###* @type {[string,string][]} ### param_replacements = []) =>
	namespace = param_replacements.map(([k]) => k).join('-') or 'global'
	actions.map (action) => {
		...action
		config_key: "action-#{namespace}-#{action.title}"
		params: action.params?.map (param) =>
			for replacement from param_replacements
				param = param.replaceAll(replacement[0], replacement[1])
			param
	}

export default defineComponent
	components: { GitPopup }
	# emits: [ 'change' ] TODO
	props:
		commit:
			###* @type {() => Commit} ###
			type: Object
			required: true
	setup: (props, { emit }) ->
		``###* @type {Ref<any>} ### # TODO import type from gitinput coffee somehow
		popup_action = ref null
		
		branch_tips = computed =>
			props.commit.refs.filter (ref) =>
				ref.type == "branch"

		stash = computed =>
			props.commit.refs.find (ref) =>
				ref.type == "stash"
		
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
		
		commit_actions = parse_config_actions config_commit_actions,
			[['{COMMIT_HASH}', props.commit.hash]]
		branch_actions = (###* @type string ### branch_name) => parse_config_actions config_branch_actions,
			[['{BRANCH_NAME}', branch_name]]
		stash_actions = parse_config_actions config_stash_actions,
			[['{COMMIT_HASH}', props.commit.hash]]

		{
			branch_tips
			stash
			changed_files
			show_diff
			body
			commit_actions
			branch_actions
			stash_actions
			popup_action
		}