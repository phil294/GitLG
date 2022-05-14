util = require('util')
exec = util.promisify(require('child_process').exec)

git =
	#
	###*
	# @param args_str {string} The arguments to pass to git verbatim (!)
	# @param cwd {string}
	###
	exec: (args_str, cwd) =>
		{ stdout, stderr } = await exec 'git ' + args_str, cwd: cwd
		stdout

module.exports = git