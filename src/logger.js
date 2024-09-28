let vscode = require('vscode')

module.exports = (/** @type {string} */ ext_name, /** @type {string} */ ext_id) => {
	let channel = vscode.window.createOutputChannel(ext_name)
	function log(/** @type {string} */ msg) {
		channel.appendLine(`${new Date().toISOString()} ${msg}`)
	}
	return {
		error(/** @type {string} */ e) {
			console.error(e)
			console.trace()
			e = `An unexpected error happened. Error summary: ${e}. For details, see VSCode developer tools console. Please consider reporting this error.`
			vscode.window.showErrorMessage(`${ext_name}: ${e}`)
			log(`[ERROR] ${e}`)
		},
		info(/** @type {string} */ msg) {
			log(`[info] ${msg}`)
		},
		debug(/** @type {string} */ msg) {
			if (! vscode.workspace.getConfiguration(ext_id).get('verbose-logging'))
				return
			log(`[debug] ${msg}`)
		},
	}
}
