import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { globSync, writeFileSync } from 'fs'

let vue_files = globSync('./src/**/*.vue').map(f => ({
	name: f.split('/').pop()?.split('.')[0],
	path: '.' + f.slice(3),
}))
let vscode_elements = globSync('./node_modules/@vscode-elements/elements/dist/vscode-*').map(f =>
	f.split('/').pop()?.slice(6).replaceAll(/(-.)/g, x => 'Vscode' + x.slice(1).toUpperCase()) || '')
writeFileSync('./src/components.d.ts', `
	// DO NOT EDIT - AUTO GENERATED FROM vite.config.js

	// This file solely exists to enable type support in Vue VSCode extension
	// https://stackoverflow.com/a/70980761/3779853

	import { HTMLAttributes } from 'vue'
	import { RecycleScroller } from 'vue-virtual-scroller'
	${vue_files.map(f => `import ${f.name} from '${f.path}'`).join('\n\t')}
	import {${vscode_elements.join(', ')}} from '@vscode-elements/elements'

	declare module '@vue/runtime-core' {
		${''/* TODO: find correct typing here */}
		${''/* https://github.com/vscode-elements/elements/issues/195#issuecomment-2907929991 */}
		type ClassToComponent<C> = DefineComponent<{}, { $props: Partial<C> & { modelValue?: any } & HTMLAttributes }>
		export interface GlobalComponents {
			RecycleScroller: typeof RecycleScroller
			${vue_files.map(f => `${f.name}: typeof ${f.name}`).join('\n\t\t\t')}
			${vscode_elements.map(f => `${f}: ClassToComponent<${f}>`).join('\n\t\t\t')}
		}
	}`)

export default defineConfig({
	plugins: [
		vue({
			template: {
				compilerOptions: {
					isCustomElement: (tag) => tag.startsWith('vscode-'),
				},
			},
		}),
		{
			// also doesn't seem to work for Vue sfcs in dev mode TODO https://github.com/vitejs/vite/issues/9825#issuecomment-2413567622
			name: 'remove-sourcemaps',
			transform(code) {
				return {
					code,
					map: { mappings: '' },
				}
			},
		},
	],
	// dev: HMR. prod: "./" as it will be affected by <base href> defined from extension.js
	base: process.env.NODE_ENV === 'production' ? './' : 'http://localhost:5173',
	build: {
		outDir: '../web-dist',
		emptyOutDir: true,
		// Make it more readable.
		// This increases output size by factor 2-3 gzipped and 4-5 unzipped though.
		minify: false,
		sourcemap: false,
		rollupOptions: {
			output: {
				entryFileNames: '[name].js',
				chunkFileNames: '[name].js',
				assetFileNames: '[name].[ext]',
			},
		},
		polyfillModulePreload: false,
	},
	server: {
		cors: true,
		headers: {
			// for codicon font
			'access-control-allow-origin': '*',
		},
	},
})
