/* global ResizeSensor */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { next } from '@ember/runloop';
import EmberObject, { action, get } from '@ember/object';
import { A as emberA } from '@ember/array';
import { assert } from '@ember/debug';
import { isPresent } from '@ember/utils';
import { registerDestructor } from '@ember/destroyable';
import { didInsert, didUpdate } from '@ember/render-modifiers';
import { closest } from '../../-private/utils/element';
import MetaCache from '../../-private/meta-cache';
import { notifyPropertyChange } from '../../-private/utils/ember';
import { sortMultiple, compareValues } from '../../-private/utils/sort';
import ColumnTree, { RESIZE_MODE, FILL_MODE, WIDTH_CONSTRAINT } from '../../-private/column-tree';
import EmberTr from '../ember-tr/component';

let isTestingThead = false;
export function setupTHeadForTest(value) { isTestingThead = value; }

export default class EmberThead extends Component {
  @tracked layoutRevision = 0;
  rowMetaCache = new Map();

  constructor(owner, args) {
    super(owner, args);
    this.columnMetaCache = new MetaCache({ keyPath: this.args.columnKeyPath });
    this.columnTree = ColumnTree.create({
      onReorder: (...values) => this.handleLayoutChange(this.args.onReorder, values),
      onResize: (...values) => this.handleLayoutChange(this.args.onResize, values),
      columnMetaCache: this.columnMetaCache,
      containerWidthAdjustment: this.args.containerWidthAdjustment,
    });
    this.validateUniqueColumnKeys();
    this.syncModels();
    this._syncedColumns = this.args.columns;
    this._syncedSorts = this.args.sorts;
    registerDestructor(this, () => this.teardown());
  }

  handleLayoutChange(callback, values) {
    this.layoutRevision++;
    callback?.(...values);
  }

  get unwrappedApi() { return this.args.api?.api ?? this.args.api; }
  get columns() { return this.args.columns ?? []; }
  get sorts() { return this.args.sorts ?? []; }
  get sortFunction() { return this.args.sortFunction ?? sortMultiple; }
  get compareFunction() { return this.args.compareFunction ?? compareValues; }
  get enableSort() { return Boolean(this.args.onUpdateSorts); }
  get enableResize() { return this.args.enableResize ?? true; }
  get enableReorder() { return this.args.enableReorder ?? true; }
  get wrappedRowsCount() { return isTestingThead ? this.wrappedRows.length : null; }

  syncModels() {
    Object.assign(this.unwrappedApi, {
      columnTree: this.columnTree,
      compareFunction: this.compareFunction,
      scrollIndicators: this.args.scrollIndicators ?? false,
      sorts: this.sorts,
      sortEmptyLast: this.args.sortEmptyLast ?? false,
      sortFunction: this.sortFunction,
    });
    this.unwrappedApi.registerColumnTree?.(this.columnTree);
    this.columnTree.setProperties({
      sorts: this.sorts,
      columns: this.columns,
      fillMode: this.args.fillMode ?? FILL_MODE.EQUAL_COLUMN,
      initialFillMode: this.args.initialFillMode ?? FILL_MODE.NONE,
      fillColumnIndex: this.args.fillColumnIndex,
      resizeMode: this.args.resizeMode ?? RESIZE_MODE.STANDARD,
      widthConstraint: this.args.widthConstraint ?? WIDTH_CONSTRAINT.NONE,
      enableSort: this.enableSort,
      enableResize: this.enableResize,
      enableReorder: this.enableReorder,
    });
    // Columns and sorts are often EmberArrays mutated in place.  In that case
    // the reference is unchanged, so invalidate the classic computed tree
    // explicitly after synchronizing the Glimmer args.
    notifyPropertyChange(this.columnTree, 'columns');
    notifyPropertyChange(this.columnTree, 'sorts');
    notifyPropertyChange(this.columnTree, '[]');
  }

  validateUniqueColumnKeys() {
    let keyPath = this.args.columnKeyPath;
    if (!keyPath) return;
    let keys = [];
    let queue = [...this.columns];
    while (queue.length) {
      let column = queue.shift();
      keys.push(get(column, keyPath));
      if (column.subcolumns) queue.push(...column.subcolumns);
    }
    let present = emberA(keys.filter(isPresent));
    assert('if columnKeyPath is specified, every column must have a key', present.length === keys.length);
    assert('if columnKeyPath is specified, no two columns can share the same key', present.uniq().length === present.length);
  }

  @action
  setup(element) {
    this.syncModels();
    this._container = closest(element, '.ember-table-overflow');
    this.columnTree.registerContainer(this._container);
    this.columnTree.performInitialLayout();
    this.layoutRevision++;
    this._tableResizeSensor = new ResizeSensor(this._container, this.fillupHandler);
  }

  @action
  syncAfterArgsChange() {
    let columns = this.args.columns;
    let sorts = this.args.sorts;
    if (columns === this._syncedColumns && sorts === this._syncedSorts) return;
    this._syncedColumns = columns;
    this._syncedSorts = sorts;
    next(this, this.syncModels);
  }

  teardown() {
    this._tableResizeSensor?.detach(this._container);
    this.columnTree.destroy();
    for (let cache of [this.columnMetaCache, this.rowMetaCache]) {
      for (let [key, meta] of cache.entries()) {
        meta.destroy();
        cache.delete(key);
      }
    }
  }

  get wrappedRows() {
    let rows = this.columnTree.rows;
    return emberA(rows.map((row, index) => {
      let rowMeta = this.rowMetaCache.get(row) ?? EmberObject.create();
      this.rowMetaCache.set(row, rowMeta);
      rowMeta.set('index', index);
      return {
        cells: emberA(row.map(columnValue => ({
          columnValue,
              columnMeta: this.columnMetaCache.get(columnValue),
              layoutRevision: this.layoutRevision,
          rowMeta,
          sorts: this.sorts,
          sendUpdateSort: this.sendUpdateSort,
        }))),
        rowMeta,
        rowsCount: rows.length,
        isHeader: true,
      };
    }));
  }

  @action sendUpdateSort(sorts) {
    this.layoutRevision++;
    this.args.onUpdateSorts?.(sorts);
    this.unwrappedApi.body?.updateSorts(sorts);
  }
  @action fillupHandler() {
    if (!this.isDestroying) {
      this.columnTree.ensureWidthConstraint();
      this.layoutRevision++;
    }
  }

  <template>
    <thead ...attributes data-test-row-count={{this.wrappedRowsCount}} data-layout-revision={{this.layoutRevision}} {{didInsert this.setup}} {{didUpdate this.syncAfterArgsChange this.args.columns this.args.sorts}}>
      {{#each this.wrappedRows as |api|}}
        {{#if (has-block)}}
          {{yield (hash
            cells=api.cells isHeader=api.isHeader rowsCount=api.rowsCount
            row=(component EmberTr api=api)
          )}}
        {{else}}
          <EmberTr @api={{api}} />
        {{/if}}
      {{/each}}
    </thead>
  </template>
}
