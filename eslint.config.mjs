import globals from 'globals'
import pluginVue from 'eslint-plugin-vue'

import path from 'path'
import { fileURLToPath } from 'url'
import { FlatCompat } from '@eslint/eslintrc'
import pluginJs from '@eslint/js'
import jsdoc from 'eslint-plugin-jsdoc'

// mimic CommonJS variables -- not needed if using CommonJS
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const compat = new FlatCompat({ baseDirectory: __dirname, recommendedConfig: pluginJs.configs.recommended })

export default [
	{ files: ['**/*.js'], languageOptions: { sourceType: 'commonjs' } },
	{ languageOptions: { globals: { ...globals.browser, ...globals.node } } },
	...compat.extends('standard'),
	...pluginVue.configs['flat/recommended'],
	jsdoc.configs['flat/recommended-typescript-flavor-error'],
	{
		files: ['**/*.js', '**/*.vue', '**/*.mjs'],
		plugins: { jsdoc },
		languageOptions: {
			globals: {
				is_truthy: 'readonly',
				is_branch: 'readonly',
				acquireVsCodeApi: 'readonly',
			},
		},
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
			'no-mixed-operators': 'off',
			'vue/prop-name-casing': ['error', 'snake_case'],
			'jsdoc/check-param-names': 'off',
			'jsdoc/require-returns-type': 'off',
			'no-undef-init': 'off',
		},
	},
]
