/** @type { import("@vue/cli-service").ProjectOptions } */
const options = {
	outputDir: '../web-dist',
	filenameHashing: false,
	productionSourceMap: false,
	devServer: {
		// for ws connection
		allowedHosts: 'all',
		headers: {
			// for codicon font
			'Access-Control-Allow-Origin': '*',
		},
	},
	// For dev only, necessary for anything loaded dynamically (HMR websocket)
	publicPath: 'http://localhost:8080',
	css: {
		loaderOptions: {
			postcss: {
				postcssOptions: {
					minimize: false,
				},
			},
		},
	},
	configureWebpack: {
	},
	chainWebpack: (config) => {
		config
			.entry('app')
			.clear()
			.add('./src/vue-app.js')

		config.devtool(false)

		// Make it more readable.
		// This increases output size by factor 2-3 gzipped and 4-5 unzipped though.
		config.optimization.minimize(false)
	},
}
module.exports = options
