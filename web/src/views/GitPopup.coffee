import { ref, defineComponent } from 'vue'
import GitInput from './GitInput.vue'

###* thin popup wrapper around GitInput ###
export default defineComponent
	inheritAttrs: false
	components: { GitInput }
	emits: [ 'close', 'change' ]
	setup: (_, { emit }) ->
		keep_open = ref false
		
		close = =>
			emit 'close'
		# pbly not on merge errors? FIXME
		success = =>
			if not keep_open.value
				close()
			emit 'change'

		{
			keep_open
			close
			success
		}