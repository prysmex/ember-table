# Ember 7 / v2 addon modernization spike

This branch moves `ember-table` from its Ember 3.28-era v1 addon to a v2 addon
written in TypeScript, tested and documented in a Vite app.

## Layout

- `ember-table/`: the published v2 addon. Components are `.gts` with Glint
  signatures; declarations are generated from source. The classic
  `ColumnTree`/`CollapseTree` models stay JavaScript and are typed at their
  boundary (`src/-private/types.ts`).
- `test-app/`: an Embroider/Vite Ember app hosting the test suite and the Docfy
  documentation site (`test-app/docs`).
- pnpm workspace; CI runs lint, tests, and `@embroider/try` scenarios.

## Verified

- Ember 7.3: 240 browser tests, 238 pass, 2 skipped (pre-existing `skip`s).
  This includes the docs acceptance tests, which were always skipped before
  and now run against the Docfy site.
- Ember 5.12 (peer floor): 232 pass, 8 skipped. The 6 extra skips are the docs
  tests, gated on Ember 6.5+ because the docs app needs it.
- `pnpm lint` passes in both packages, including `ember-tsc` type-checking.
- The emitted declarations type-check from a consumer `.gts` app, and reject
  rows of the wrong shape.

## Notable decisions

- Components derive state through autotracking. The classic models read their
  inputs from component getters (`readOnly` aliases on `@dependentKeyCompat`
  getters) instead of having arguments pushed in.
- `hammerjs` is loaded with `importSync` when a header is set up, so evaluating
  the addon never touches `window` (FastBoot).
- Try scenarios are applied to both packages so the addon's dev copy of
  `ember-source` matches the app under test; otherwise its modules resolve a
  second Ember.
- The sticky polyfill registers its initial animation frame with
  `@ember/test-waiters`, which removed a flaky test (and the same race in
  consumers' tests).

## Follow-ups

- Replace `@ember/render-modifiers` with `ember-modifier` (or local modifiers).
- Modernize the classic models, after which they can move to TypeScript.
- `data-test-*` attributes now ship in production builds (v2 addons cannot be
  stripped by `ember-test-selectors`).
- Docs deployment (GitHub Pages) needs a new workflow for the Docfy site.
