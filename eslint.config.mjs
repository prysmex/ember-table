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
  { ignores: ['dist/', 'node_modules/', 'coverage/', '!**/.*'] },
  {
    files: ['**/*.js'],
    languageOptions: { parser: babelParser },
  },
  {
    files: ['**/*.{js,gjs}'],
    languageOptions: {
      parserOptions,
      globals: { ...globals.browser, FastBoot: 'readonly', Hammer: 'readonly', ResizeSensor: 'readonly' },
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
];
