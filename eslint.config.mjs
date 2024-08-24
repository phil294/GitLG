import globals from 'globals'
import pluginVue from 'eslint-plugin-vue'

import path from 'path'
import { fileURLToPath } from 'url'
import { FlatCompat } from '@eslint/eslintrc'
import pluginJs from '@eslint/js'

// mimic CommonJS variables -- not needed if using CommonJS
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const compat = new FlatCompat({ baseDirectory: __dirname, recommendedConfig: pluginJs.configs.recommended })

export default [
	{ files: ['**/*.js'], languageOptions: { sourceType: 'commonjs' } },
	{ languageOptions: { globals: { ...globals.browser, ...globals.node } } },
	...compat.extends('standard'),
	...pluginVue.configs['flat/recommended'],
	{
		files: ['**/*.js', '**/*.vue', '**/*.mjs'],
		rules: {
			'prefer-const': 'off',
			camelcase: 'off', // eslint-plugin-snakecasejs also doesn't work properly
			indent: ['error', 'tab'],
			quotes: ['error'],
			'no-tabs': 'off',
			'space-before-function-paren': ['error', {
				anonymous: 'never',
				named: 'never',
				asyncArrow: 'always',
			}],
			curly: ['error', 'multi'],
			'nonblock-statement-body-position': ['error', 'below'],
			'comma-dangle': ['error', 'always-multiline'],
			'func-style': ['error', 'declaration', { allowArrowFunctions: true }],
			'arrow-body-style': ['error', 'as-needed'],
			'no-return-assign': 'off',
			'no-throw-literal': 'off',
			'space-unary-ops': ['error', {
				words: true,
				nonwords: true,
				overrides: {
					'++': false,
					'--': false,
					'-': false,
				},
			}],
			'no-extra-parens': ['error', 'all'],
			semi: ['error', 'never', { beforeStatementContinuationChars: 'never' }],
			'no-extra-semi': 'error',
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
		},
	},
]
