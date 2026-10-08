import globals from 'globals';
import js from '@eslint/js';
import ember from 'eslint-plugin-ember/recommended';
import eslintConfigPrettier from 'eslint-config-prettier';
import qunit from 'eslint-plugin-qunit';
import n from 'eslint-plugin-n';
import babelParser from '@babel/eslint-parser';

// Parse standalone: the app's babel config is async and build-oriented.
const parserOptions = {
  requireConfigFile: false,
  babelOptions: {
    configFile: false,
    babelrc: false,
    plugins: [['@babel/plugin-proposal-decorators', { version: 'legacy' }]],
  },
};

export default [
  js.configs.recommended,
  eslintConfigPrettier,
  ember.configs.base,
  ember.configs.gjs,
  { ignores: ['dist/', 'tmp/', 'node_modules/', 'app/templates/docs/'] },
  {
    // Test fixtures deliberately exercise the classic APIs ember-table supports.
    rules: {
      'ember/no-get': 'off',
      'ember/no-classic-classes': 'off',
      'ember/no-classic-components': 'off',
      'ember/require-tagless-components': 'off',
      'ember/no-runloop': 'off',
    },
  },
  {
    files: ['**/*.js'],
    languageOptions: { parser: babelParser, parserOptions },
  },
  {
    files: ['**/*.gjs'],
    languageOptions: { parserOptions },
  },
  {
    files: ['**/*.{js,gjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { ...globals.browser },
    },
  },
  {
    ...qunit.configs.recommended,
    files: ['tests/**/*-test.{js,gjs}'],
    plugins: { qunit },
  },
  {
    ...n.configs['flat/recommended-script'],
    files: ['**/*.cjs', 'config/**/*.js'],
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
      globals: { ...globals.node },
    },
    rules: { 'n/no-unpublished-import': 'off' },
  },
];
