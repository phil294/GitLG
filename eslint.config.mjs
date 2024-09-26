import globals from 'globals'
import neostandard from 'neostandard'
import pluginVue from 'eslint-plugin-vue'
import jsdoc from 'eslint-plugin-jsdoc'

/** @type {import('eslint').Linter.Config[]} */
export default [
	...neostandard({}),
	{ files: ['**/*.js'], languageOptions: { sourceType: 'commonjs' } },
	{ languageOptions: { globals: { ...globals.browser, ...globals.node } } },
	//  TODO: https://github.com/vuejs/eslint-plugin-vue/issues/2555
	.../** @type {any} */(pluginVue.configs['flat/recommended']), // eslint-disable-line @stylistic/no-extra-parens
	jsdoc.configs['flat/recommended-typescript-flavor-error'],
	{
		files: ['**/*.js', '**/*.vue', '**/*.mjs'],
		plugins: { jsdoc },
		languageOptions: {
			globals: {
				is_truthy: 'readonly',
				is_branch: 'readonly',
				acquireVsCodeApi: 'readonly',
				debounce: 'readonly',
			},
		},
		rules: {
			'prefer-const': 'off',
			camelcase: 'off', // eslint-plugin-snakecasejs also doesn't work properly
			'@stylistic/indent': ['error', 'tab'],
			quotes: ['error', 'single'],
			'@stylistic/no-tabs': 'off',
			'@stylistic/space-before-function-paren': ['error', {
				anonymous: 'never',
				named: 'never',
				asyncArrow: 'always',
			}],
			curly: ['error', 'multi'],
			'nonblock-statement-body-position': ['error', 'below'],
			'@stylistic/comma-dangle': ['error', 'always-multiline'],
			'func-style': ['error', 'declaration', { allowArrowFunctions: true }],
			'arrow-body-style': ['error', 'as-needed'],
			'no-return-assign': 'off',
			'no-throw-literal': 'off',
			'@stylistic/space-unary-ops': ['error', {
				words: true,
				nonwords: true,
				overrides: {
					'++': false,
					'--': false,
					'-': false,
				},
			}],
			'@stylistic/no-extra-parens': ['error', 'all'],
			semi: ['error', 'never', { beforeStatementContinuationChars: 'never' }],
			'@stylistic/no-extra-semi': 'error',
			'init-declarations': ['error', 'always'],
			'vue/html-indent': ['error', 'tab'],
			'vue/max-attributes-per-line': 'off',
			'vue/max-len': 'off',
			'vue/singleline-html-element-content-newline': ['error', {
				ignoreWhenNoAttributes: false,
				ignoreWhenEmpty: false, // not respected, stays at true??
			}],
			'vue/multiline-html-element-content-newline': ['error', {
				ignoreWhenEmpty: false,
			}],
			'no-extend-native': 'off',
			'promise/param-names': 'off',
			'jsdoc/require-jsdoc': 'off',
			'jsdoc/require-returns': 'off',
			'jsdoc/require-param': 'off',
			'jsdoc/no-undefined-types': 'off', // can't detect global types, and type errors are reported by strict jsconfig anyway
			'jsdoc/require-returns-description': 'off',
			'jsdoc/require-param-type': 'off',
			'vue/multi-word-component-names': 'off',
			'no-shadow': 'error',
			'vue/return-in-computed-property': 'off',
			'@stylistic/no-mixed-operators': 'off',
			'vue/prop-name-casing': ['error', 'snake_case'],
			'jsdoc/check-param-names': 'off',
			'jsdoc/require-returns-type': 'off',
			'no-undef-init': 'off',
			'import/first': 'off', // brakes script setup + extra script for exports
		},
	},
]
