import { git, open_diff } from '../store.coffee'
import { Commit } from '../log-utils.coffee'
import { ref, Ref, computed, defineComponent, watchEffect } from 'vue'
import GitInput from './GitInput.vue'

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

		``###* @type {Ref<string[][]>} ###
		changed_files = ref []
		watchEffect =>
			changed_files.value = (await git "diff --numstat --format='' #{props.commit.hash} #{props.commit.hash}~1")
				.split('\n').map((l) => l.split('\t'))
		
		show_diff = (###* @type string ### file) =>
			open_diff props.commit.hash, file[2]

		{
			args
			branch_tips
			git_execute_success
			keep_open
			changed_files
			show_diff
		}