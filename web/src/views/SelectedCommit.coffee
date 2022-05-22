import { git } from '../store.coffee'
import { Commit } from '../log-utils.coffee'
import { ref, computed, defineComponent } from 'vue'
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
		args = ref null
		
		branch_tips = computed =>
			props.commit.refs.filter (ref) =>
				ref.type == "branch"
		
		keep_open = ref false
		
		git_execute_success = =>
			if not keep_open.value
				args.value = null
				emit 'change' # todo this is actually independent of keep_open :/

		do_git = (###* @type string ### args) =>
			await git args
			emit 'change'

		{
			args
			branch_tips
			git_execute_success
			keep_open
			do_git
		}