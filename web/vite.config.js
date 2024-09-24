import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
	plugins: [vue()],
	// dev: HMR. prod: "./" as it will be affected by <base href> defined from extension.js
	base: process.env.NODE_ENV === 'production' ? './' : 'http://localhost:5173',
	build: {
		outDir: '../web-dist',
		emptyOutDir: true,
		// Make it more readable.
		// This increases output size by factor 2-3 gzipped and 4-5 unzipped though.
		minify: false,
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
