import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));

export default {
  sections: {
    guides: { label: 'Guides', order: 1 },
    main: { label: 'Basics', order: 1 },
    header: { label: 'Header', order: 2 },
    body: { label: 'Body', order: 3 },
    testing: { label: 'Testing', order: 2 },
  },
  repository: {
    url: 'https://github.com/Addepar/ember-table',
    editBranch: 'master',
  },
  sources: [
    {
      root: path.join(root, 'docs'),
      pattern: '**/*.md',
      urlPrefix: 'docs',
    },
  ],
};
