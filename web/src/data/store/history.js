import state from '../state.js'

/** @type {HistoryEntry[]} */
let default_history = []
export let history = state('repo:action-history', default_history).ref
export let push_history = (/** @type {HistoryEntry} */ entry) => {
	entry.datetime = new Date().toISOString()
	let _history = history.value?.slice() || []
	let last_entry = _history.at(-1)
	switch (entry.type) {
		case 'git':
			if (entry.value.startsWith('log '))
				return
	}
	if (last_entry?.type === entry.type)
		switch (entry.type) {
			case 'txt_filter':
				if (last_entry?.value === entry.value)
					return
				if (last_entry)
					last_entry.value = entry.value
				break
			case 'branch_id': case 'commit_hash': case 'git':
				if (last_entry?.value === entry.value)
					return
				_history.push(entry)
				break
			default:
				throw `Unexpected history entry type ${entry.type}`
		}
	else
		_history.push(entry)
	if (_history.length > 100)
		_history.shift()
	history.value = _history
}
