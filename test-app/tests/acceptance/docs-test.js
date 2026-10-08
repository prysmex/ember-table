import { module, test } from 'qunit';
import { currentURL, findAll, visit } from '@ember/test-helpers';
import { setupApplicationTest } from 'ember-qunit';
import { dependencySatisfies, macroCondition } from '@embroider/macros';
import TablePage from 'ember-table/test-support/pages/ember-table';

// The docs site (Docfy, template-tag route templates) needs Ember 6.5+, while
// the addon's own tests also run on older try scenarios.
const docsModule = macroCondition(dependencySatisfies('ember-source', '>= 6.5.0'))
  ? module
  : module.skip;

docsModule('Acceptance | docs', function (hooks) {
  setupApplicationTest(hooks);

  test('visiting / redirects to the docs', async function (assert) {
    await visit('/');

    assert.true(currentURL().startsWith('/docs'), `redirected to ${currentURL()}`);
  });

  test('every page in the docs navigation renders', async function (assert) {
    await visit('/docs');

    let hrefs = findAll('.docs-nav a').map((link) => link.getAttribute('href'));
    assert.true(hrefs.length > 10, `${hrefs.length} pages linked from the navigation`);

    for (let href of hrefs) {
      await visit(href);
      assert.dom('.docs-content h1').exists(`${href} renders its title`);
    }
  });

  test('live demos render tables', async function (assert) {
    await visit('/docs/guides/main/basic-table');

    assert.dom('.docfy-demo .ember-table').exists({ count: 2 });
    assert.dom('.docfy-demo .ember-table tbody td').exists();
  });

  test('scenario pages render', async function (assert) {
    for (let path of ['/scenarios/simple', '/scenarios/performance', '/scenarios/blank']) {
      await visit(path);
      assert.strictEqual(currentURL(), path, `${path} renders`);
    }
  });

  test('subcolumns docs renders cell content', async function (assert) {
    let DemoTable = TablePage.extend({
      scope: '[data-test-demo="docs-example-subcolumns"] [data-test-ember-table]',
    });

    await visit('/docs/guides/header/subcolumns');
    let table = new DemoTable();
    assert.strictEqual(table.header.headers.objectAt(0).text, 'A', 'first header cell renders');
    assert.strictEqual(
      table.body.rows.objectAt(0).cells.objectAt(0).text,
      'A A',
      'first body cell renders'
    );
  });

  test('sorting: 2-state sorting cycles between descending and ascending', async function (assert) {
    let DemoTable = TablePage.extend({
      scope: '[data-test-demo="docs-example-2-state-sortings"] [data-test-ember-table]',
    });

    await visit('/docs/guides/header/sorting');
    let header = new DemoTable().headers.objectAt(0);

    assert.false(header.sortIndicator.isPresent, 'precond - sortIndicator is not present');

    await header.click();
    assert.true(header.sortIndicator.isDescending, 'sort descending');

    await header.click();
    assert.true(header.sortIndicator.isAscending, 'sort ascending');

    await header.click();
    assert.true(header.sortIndicator.isDescending, 'sort cycles back to descending');
  });
});
