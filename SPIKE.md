# Ember 7 / GJS modernization spike

This branch tests upgrading `ember-table` from its Ember 3.28-era addon
blueprint to the current Ember CLI addon blueprint and moving every shipped
component to GJS.

## Baseline

- Source branch: `master`
- Ember CLI / Ember Source: 3.28
- Node: 18.20.5
- Test surface: 202 tests in 26 modules
- Compatibility matrix: Ember 3.28, 4.4, 4.12, 5.4, 5.12, current release,
  and Embroider safe
- Components: 14 JavaScript component modules and 10 separate templates

The existing suite covers the public table composition API, cells, headers,
rows, footers, selection, sorting, resizing, reordering, tree behavior,
loading-more behavior, scroll indicators, metadata, and the sticky-table
polyfill. These tests are the behavioral characterization suite for the
migration.

## Target

- Ember CLI / Ember Source 7.3
- Node 20.19 or newer
- Current classic-build-addon blueprint structure and lint/test tooling
- All addon component modules represented as `.gjs`; paired templates are
  colocated into their component modules where practical
- Ember release, beta, canary, and Embroider safe/optimized CI coverage

## Baseline test note

The first frozen-lockfile install stalled in Yarn 1's linking phase and was
stopped. The partial dependency tree did not contain the `ember` executable,
so the pre-migration suite could not be executed locally. Existing CI and the
test sources are therefore the baseline until the modernized dependency tree
can be installed.

## Spike result

- The current Ember 7.3 classic-build-addon blueprint dependencies install
  under Node 22 and npm.
- Every shipped addon component now uses a native `@glimmer/component` class
  with an embedded `<template>` block. The separate addon `.hbs` files have
  been removed. The table's non-component models (`CollapseTree`, `ColumnTree`,
  and cached row/cell metadata) intentionally remain EmberObject-based.
- `npm run lint` passes.
- `npm run build` produces a production build on Ember 7.3.
- `npm run test:ember` builds the test application successfully, but this
  development container has no Chrome-compatible browser. A Playwright
  Chromium install was also unavailable for its Ubuntu ARM64 platform, so the
  202 browser assertions must be confirmed in CI.

DOM ownership and component lifecycle behavior now live in templates and
modifiers. Classic EmberObject APIs remain only in the table's model/cache
layer and can be modernized independently of the component migration.
