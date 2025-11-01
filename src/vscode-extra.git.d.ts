// Types that are missing from the official .d.ts (see sibling file)
// but are actually there:

export interface Git {
	readonly path: string;
	readonly env?: Record<string, string>;
}
export interface API {
	readonly git: Git;
}
