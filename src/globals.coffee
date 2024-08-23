String.prototype.hashCode = ->
	hash = 0
	return hash if @length == 0
	for _,i in this
		chr = this.charCodeAt(i)
		hash = ((hash << 5) - hash) + chr
		hash |= 0
	hash

###* Call this with *args* and silently return `undefined` on error. ###
Function.prototype.maybe = (args) ->
	try
		return this(...args)
	catch
		undefined

###* Catch and ignore. Like `.catch(() => undefined)`. ###
Promise.prototype.maybe = ->
	this.catch(=>)