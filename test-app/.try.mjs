// Scenarios for `pnpm dlx @embroider/try`, run from this directory.
// ember-source 6.4 is the addon's peer dependency floor.
export default {
  scenarios: [
    {
      name: 'ember-lts-6.4',
      npm: { devDependencies: { 'ember-source': '~6.4.0' } },
    },
    {
      name: 'ember-latest',
      npm: { devDependencies: { 'ember-source': 'npm:ember-source@latest' } },
    },
    {
      name: 'ember-beta',
      npm: { devDependencies: { 'ember-source': 'npm:ember-source@beta' } },
    },
    {
      name: 'ember-alpha',
      npm: { devDependencies: { 'ember-source': 'npm:ember-source@alpha' } },
    },
  ],
};
