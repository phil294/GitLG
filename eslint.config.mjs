import globals from 'globals'
import neostandard from 'neostandard'
import plugin_vue from 'eslint-plugin-vue'
import jsdoc from 'eslint-plugin-jsdoc'
import js from '@eslint/js'
import ts_eslint from 'typescript-eslint'
import { defineConfig } from '@eslint/config-helpers'

/** @type {import('eslint').Linter.Config[]} */
export default defineConfig([
	js.configs.recommended,
	...ts_eslint.configs.strictTypeChecked,
	...ts_eslint.configs.stylisticTypeChecked,
	{ languageOptions: { parserOptions: { projectService: true } } },
	...neostandard({}),
	{ files: ['**/*.js'], languageOptions: { sourceType: 'commonjs' } },
	{ languageOptions: { globals: { ...globals.browser, ...globals.node } } },
	...plugin_vue.configs['flat/recommended'],
	jsdoc.configs['flat/recommended-typescript-flavor-error'],
	{ ignores: ['web-dist', 'node_modules', '.vscode/.history'] },
	{
		files: ['**/*.js', '**/*.vue', '**/*.mjs', '**/*.ts'],
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
			camelcase: 'off',
			'@typescript-eslint/naming-convention': ['warn', {
				selector: 'default',
				format: ['snake_case'],
				leadingUnderscore: 'allow',
				trailingUnderscore: 'allow',
			}, {
				selector: 'import',
				format: ['snake_case', 'PascalCase'],
			}, {
				selector: 'typeLike',
				format: ['PascalCase'],
			}, {
				// https://github.com/typescript-eslint/typescript-eslint/issues/6120#issuecomment-1595583999
				selector: 'objectLiteralProperty',
				format: null,
			},
			],
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
			'jsdoc/require-param-description': 'off',
			'jsdoc/require-param-type': 'off',
			'jsdoc/valid-types': 'off', // not reliable enough and TS itself 9/10 times catches the errors
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
			'@typescript-eslint/no-unused-vars': ['warn', { varsIgnorePattern: '^_.*', argsIgnorePattern: '^_.*', caughtErrorsIgnorePattern: '^_.*' }],
			'no-sequences': 'off',
			'@stylistic/object-property-newline': 'off',
			'@stylistic/lines-between-class-members': 'off',
			'@typescript-eslint/no-import-type-side-effects': 'warn',
			'@typescript-eslint/no-unsafe-type-assertion': 'warn',
			'@typescript-eslint/strict-boolean-expressions': ['warn', { allowNullableBoolean: true }],
			'@typescript-eslint/switch-exhaustiveness-check': 'warn',
		},
	},
])
