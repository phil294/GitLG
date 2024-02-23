String.prototype.hashCode = ->
	hash = 0
	return hash if @length == 0
	for _,i in this
		chr = this.charCodeAt(i)
		hash = ((hash << 5) - hash) + chr
		hash |= 0
	hash