import globals from 'globals'
import neostandard from 'neostandard'
import pluginVue from 'eslint-plugin-vue'
import jsdoc from 'eslint-plugin-jsdoc'

/** @type {import('eslint').Linter.Config[]} */
export default [
	...neostandard({}),
	{ files: ['**/*.js'], languageOptions: { sourceType: 'commonjs' } },
	{ languageOptions: { globals: { ...globals.browser, ...globals.node } } },
	...pluginVue.configs['flat/recommended'],
	jsdoc.configs['flat/recommended-typescript-flavor'],
	{
		files: ['**/*.js', '**/*.vue', '**/*.mjs'],
		plugins: { jsdoc },
		languageOptions: {
			globals: {
				not_null: 'readonly',
				sleep: 'readonly',
				is_truthy: 'readonly',
				is_branch: 'readonly',
				acquireVsCodeApi: 'readonly',
				debounce: 'readonly',
			},
		},
		settings: {
			jsdoc: {
				mode: 'typescript',
			},
		},
		rules: {
			'prefer-const': 'off',
			camelcase: 'off', // eslint-plugin-snakecasejs also doesn't work properly
			'@stylistic/indent': ['warn', 'tab'],
			quotes: ['warn', 'single'],
			'@stylistic/no-tabs': 'off',
			'@stylistic/space-before-function-paren': ['warn', {
				anonymous: 'never',
				named: 'never',
				asyncArrow: 'always',
			}],
			curly: ['warn', 'multi'],
			'nonblock-statement-body-position': ['warn', 'below'],
			'@stylistic/comma-dangle': ['warn', 'always-multiline'],
			'func-style': ['warn', 'declaration', { allowArrowFunctions: true }],
			'arrow-body-style': ['warn', 'as-needed'],
			'no-return-assign': 'off',
			'no-throw-literal': 'off',
			'@stylistic/space-unary-ops': ['warn', {
				words: true,
				nonwords: true,
				overrides: {
					'++': false,
					'--': false,
					'-': false,
				},
			}],
			'@stylistic/no-extra-parens': ['off'],
			semi: ['warn', 'never', { beforeStatementContinuationChars: 'never' }],
			'@stylistic/no-extra-semi': 'warn',
			'init-declarations': ['warn', 'always'],
			'vue/html-indent': ['warn', 'tab'],
			'vue/max-attributes-per-line': 'off',
			'vue/max-len': 'off',
			'vue/singleline-html-element-content-newline': ['warn', {
				ignoreWhenNoAttributes: false,
				ignoreWhenEmpty: false, // not respected, stays at true??
			}],
			'vue/multiline-html-element-content-newline': ['warn', {
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
			'no-shadow': 'warn',
			'vue/return-in-computed-property': 'off',
			'@stylistic/no-mixed-operators': 'off',
			'vue/prop-name-casing': ['warn', 'snake_case'],
			'jsdoc/check-param-names': 'off',
			'jsdoc/require-returns-type': 'off',
			'no-undef-init': 'off',
			'import/first': 'off', // breaks script setup + extra script for exports
			'@stylistic/multiline-ternary': 'off',
			'no-unused-vars': ['warn', { varsIgnorePattern: '^_.*', argsIgnorePattern: '^_.*', caughtErrorsIgnorePattern: '^_.*' }],
			'no-sequences': 'off',
			'@stylistic/object-property-newline': 'off',
		},
	},
]
