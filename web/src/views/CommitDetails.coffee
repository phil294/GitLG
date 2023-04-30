import { git, open_diff, get_config } from '../bridge.coffee'
import { Commit } from './log-utils.coffee'
import { ref, Ref, computed, defineComponent, watchEffect } from 'vue'
import { parse_config_actions } from './GitInput.coffee'
import GitActionButton from './GitActionButton.vue'

export default defineComponent
	emits: ['change']
	components: { GitActionButton }
	props:
		commit:
			###* @type {() => Commit} ###
			type: Object
			required: true
	setup: (props) ->
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
			open_diff props.commit.hash, filepath
		
		config_branch_actions = ref []
		config_commit_actions = ref []
		config_stash_actions = ref []
		do =>
			config_branch_actions.value = await get_config 'actions.branch'
			config_commit_actions.value = await get_config 'actions.commit'
			config_stash_actions.value = await get_config 'actions.stash'
		commit_actions = computed => parse_config_actions config_commit_actions.value,
			[['{COMMIT_HASH}', props.commit.hash]]
		branch_actions = (###* @type string ### branch_name) => parse_config_actions config_branch_actions.value,
			[['{BRANCH_NAME}', branch_name]]
		stash_actions = computed => parse_config_actions config_stash_actions.value,
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
		}