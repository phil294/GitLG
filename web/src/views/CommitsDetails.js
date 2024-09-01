import { ref, Ref, computed, defineComponent, watchEffect } from 'vue'
import { git, exchange_message } from '../bridge.js'
import { commits_actions } from './store.js'

export default defineComponent({
	props: {
		commits: {
			/** @type {() => Commit[]} */
			type: Object,
			required: true,
		},
	},
	setup(props) {
		/** @type {Ref<{path:string,insertions:number,deletions:number}[]>} */
		let comparison_files = ref([])
		watchEffect(async () => {
			if (props.commits.length !== 2)
				return
			let get_files_command = `-c core.quotepath=false diff --numstat --format="" ${props.commits[0].hash} ${props.commits[1].hash}`
			// TODO externalize? subcomponent?
			comparison_files.value = ((await git(get_files_command).maybe()))?.split('\n').map((l) => {
				let split = l.split('\t')
				return {
					path: split[2],
					insertions: Number(split[1]),
					deletions: Number(split[0]),
				}
			}) || []
		})

		function show_compare_diff(/** @type {string} */ filepath) {
			exchange_message('open-diff', {
				hashes: [props.commits[0].hash, props.commits[1].hash],
				filename: filepath,
			})
		}
		function view_rev(/** @type {string} */ filepath) {
			exchange_message('view-rev', {
				hash: props.commits[1].hash,
				filename: filepath,
			})
		}
		let _commits_actions = computed(() => commits_actions(props.commits.map((c) => c.hash)).value)

		return {
			comparison_files,
			show_compare_diff,
			view_rev,
			commits_actions: _commits_actions,
		}
	},
})
