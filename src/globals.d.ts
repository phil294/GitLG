declare interface String {
	hashCode(): number
}

declare interface Function {
	/** Call *this* with *args* and silently return `undefined` on error. */
	maybe<T>(this: (...args: S) => T, args?: S): T | undefined
}


declare interface Promise<T> {
	/** Catch and ignore. Like `.catch(() => undefined)`. */
	maybe(): Promise<T | undefined>
}
