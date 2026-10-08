import { defineConfig } from 'vite';
import { extensions, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import docfy from '@docfy/ember-vite';

export default defineConfig(({ mode }) => ({
  plugins: [
    docfy(),
    ember(),
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
  ],
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        // The test suite is only built for `--mode development` (see `pnpm test`).
        ...(mode === 'production' ? {} : { tests: 'tests/index.html' }),
      },
    },
  },
}));
