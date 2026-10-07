'use strict';

const getChannelURL = require('ember-source-channel-url');
const { embroiderSafe, embroiderOptimized } = require('@embroider/test-setup');

module.exports = async function() {
  return {
    packageManager: 'npm',
    scenarios: [
      embroiderSafe(),
      embroiderOptimized(),
      {
        name: 'ember-lts-5.12',
        npm: {
          devDependencies: {
            'ember-source': '~5.12.0',
          },
        },
      },
      {
        name: 'ember-lts-6.4',
        npm: {
          devDependencies: {
            'ember-source': '~6.4.0',
          },
        },
      },
      {
        name: 'ember-release',
        npm: {
          devDependencies: {
            'ember-source': await getChannelURL('release'),
          },
        },
      },
      {
        name: 'ember-beta',
        npm: {
          devDependencies: {
            'ember-source': await getChannelURL('beta'),
          },
        },
      },
      {
        name: 'ember-canary',
        npm: {
          devDependencies: {
            'ember-source': await getChannelURL('canary'),
          },
        },
      },
      {
        name: 'ember-default',
        npm: {
          devDependencies: {},
        },
      },
      {
        name: 'ember-production',
        command: 'ember test -e production',
        npm: {
          devDependencies: {},
        },
      },
      {
        name: 'ember-default-docs',
        command: 'ember test --filter="Acceptance | docs"',
        npm: {
          devDependencies: {
            'ember-data': '~3.24.0',
            'ember-cli-addon-docs': '^5.2.0',
            'ember-cli-addon-docs-yuidoc': '^1.0.0',
            'ember-cli-deploy': '^1.0.2',
            'ember-cli-deploy-build': '^1.1.1',
            'ember-cli-deploy-git': '^1.3.3',
            'ember-cli-deploy-git-ci': '^1.0.1',
          },
          resolutions: {
            '@handlebars/parser': '~2.1.0',
            'ember-cli-addon-docs/broccoli-plugin': '4.0.7',
            '@types/broccoli-plugin/broccoli-plugin': '4.0.7',
          },
        },
      },
    ],
  };
};
