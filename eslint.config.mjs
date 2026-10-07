import globals from 'globals';
import js from '@eslint/js';
import ember from 'eslint-plugin-ember/recommended';
import eslintConfigPrettier from 'eslint-config-prettier';
import qunit from 'eslint-plugin-qunit';
import n from 'eslint-plugin-n';
import babelParser from '@babel/eslint-parser';

const parserOptions = {
  ecmaFeatures: { modules: true },
  ecmaVersion: 'latest',
  requireConfigFile: false,
  babelOptions: {
    plugins: [['@babel/plugin-proposal-decorators', { decoratorsBeforeExport: true }]],
  },
};

export default [
  js.configs.recommended,
  eslintConfigPrettier,
  ember.configs.base,
  ember.configs.gjs,
  { ignores: ['dist/', 'node_modules/', 'coverage/', 'types/', '.eslintrc.js'] },
  {
    // This spike changes module and template formats without also rewriting the
    // addon's mature classic-object internals. Keep those separate migrations
    // visible, but do not make them a prerequisite for validating GJS output.
    rules: {
      'ember/no-get': 'off',
      'ember/no-classic-classes': 'off',
      'ember/no-classic-components': 'off',
      'ember/no-runloop': 'off',
      'ember/require-computed-property-dependencies': 'off',
      'ember/require-tagless-components': 'off',
      'ember/no-component-lifecycle-hooks': 'off',
      'ember/no-at-ember-render-modifiers': 'off',
    },
  },
  {
    files: ['**/*.js'],
    languageOptions: { parser: babelParser },
  },
  {
    files: ['**/*.{js,gjs}'],
    languageOptions: {
      parserOptions,
      globals: { ...globals.browser },
    },
  },
  {
    files: ['**/*.gjs'],
    languageOptions: { globals: { hash: 'readonly' } },
    rules: {
      'no-unused-vars': 'off',
      'ember/no-computed-properties-in-native-classes': 'off',
      'ember/no-side-effects': 'off',
    },
  },
  {
    ...qunit.configs.recommended,
    files: ['tests/**/*-test.{js,gjs}'],
    plugins: { qunit },
  },
  {
    ...n.configs['flat/recommended-script'],
    files: ['config/**/*.js', 'tests/dummy/config/**/*.js', 'testem.js', 'index.js', '.prettierrc.js', '.template-lintrc.js', 'ember-cli-build.js'],
    plugins: { n },
    languageOptions: {
      sourceType: 'script',
      ecmaVersion: 'latest',
      globals: { ...globals.node },
    },
  },
  {
    ...n.configs['flat/recommended-module'],
    files: ['**/*.mjs'],
    plugins: { n },
    languageOptions: {
      sourceType: 'module',
      ecmaVersion: 'latest',
      parserOptions,
      globals: { ...globals.node },
    },
  },
  {
    files: ['eslint.config.mjs'],
    rules: { 'n/no-unpublished-import': 'off' },
  },
];
