/** @type { import("@vue/cli-service").ProjectOptions } */
const options = {
	outputDir: '../web-dist',
	filenameHashing: false,
	productionSourceMap: false,
	css: {
		loaderOptions: {
			postcss: {
				postcssOptions: {
					minimize: false,
				},
			},
			stylus: {
				stylusOptions: {
					compress: false,
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
			.add('./src/vue-app.coffee')

		config.resolve.extensions
			.add('.coffee')

		config.devtool(false)
		config.module
			.rule('coffee')
				.use('coffee-loader')
				.tap(options => ({
					...options,
					sourceMap: false
				}))

		// No minimization increases output size by factor 2-3 gzipped and 4-5 unzipped.
		config.optimization.minimize(false)

		config.module
			.rule('slm')
				.test(/\.slm$/)
				.oneOf('vue-loader')
					.resourceQuery(/^\?vue/)
					.use('slm/loader')
						.loader('vue-slm-lang-loader')
	}
}
module.exports = options