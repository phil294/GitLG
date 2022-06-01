util = require('util')
exec = util.promisify(require('child_process').exec)

git =
	###*
	# @param args_str {string} The arguments to pass to git verbatim (!)
	# @param cwd {string}
	###
	exec: (args_str, cwd) =>
		{ stdout, stderr } = await exec 'git ' + args_str,
			cwd: cwd
			# 35 MB. For scale, Linux kernel git graph (1 mio commits) in extension format is 538 MB or 7.4 MB for the first 15k commits
			maxBuffer: 1024 * 1024 * 35
		stdout

module.exports = git