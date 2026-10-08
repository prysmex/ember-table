/* global ResizeSensor */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import EmberObject, { action, get } from '@ember/object';
import { readOnly } from '@ember/object/computed';
import { dependentKeyCompat } from '@ember/object/compat';
import { A as emberA } from '@ember/array';
import { assert } from '@ember/debug';
import { isPresent } from '@ember/utils';
import { registerDestructor } from '@ember/destroyable';
import { didInsert, didUpdate } from '@ember/render-modifiers';
import { closest } from '../../-private/utils/element';
import MetaCache from '../../-private/meta-cache';
import { sortMultiple, compareValues } from '../../-private/utils/sort';
import ColumnTree, { RESIZE_MODE, FILL_MODE, WIDTH_CONSTRAINT } from '../../-private/column-tree';
import EmberTr from '../ember-tr/component';

let isTestingThead = false;
export function setupTHeadForTest(value) {
  isTestingThead = value;
}

const EMPTY = Object.freeze([]);

// The column tree is a classic model. Rather than pushing Glimmer args into it
// whenever they change, its inputs are aliases of the header's getters, so the
// model's computed properties and observers stay in sync through autotracking.
const HeadColumnTree = ColumnTree.extend({
  columns: readOnly('_head.columns'),
  sorts: readOnly('_head.sorts'),
  fillMode: readOnly('_head.fillMode'),
  initialFillMode: readOnly('_head.initialFillMode'),
  fillColumnIndex: readOnly('_head.fillColumnIndex'),
  resizeMode: readOnly('_head.resizeMode'),
  widthConstraint: readOnly('_head.widthConstraint'),
  containerWidthAdjustment: readOnly('_head.containerWidthAdjustment'),
  enableSort: readOnly('_head.enableSort'),
  enableResize: readOnly('_head.enableResize'),
  enableReorder: readOnly('_head.enableReorder'),
});

export default class EmberThead extends Component {
  rowMetaCache = new Map();

  constructor(owner, args) {
    super(owner, args);

    this.columnMetaCache = new MetaCache({ keyPath: this.args.columnKeyPath });
    this.columnTree = HeadColumnTree.create({
      _head: this,
      columnMetaCache: this.columnMetaCache,
      onReorder: (...values) => this.args.onReorder?.(...values),
      onResize: (...values) => this.args.onResize?.(...values),
    });

    this.validateUniqueColumnKeys();
    this.unwrappedApi.registerHead(this);

    registerDestructor(this, () => this.teardown());
  }

  get unwrappedApi() {
    return this.args.api?.api ?? this.args.api;
  }

  @dependentKeyCompat get columns() { return this.args.columns ?? EMPTY; }
  @dependentKeyCompat get sorts() { return this.args.sorts ?? EMPTY; }
  @dependentKeyCompat get fillMode() { return this.args.fillMode ?? FILL_MODE.EQUAL_COLUMN; }
  @dependentKeyCompat get initialFillMode() { return this.args.initialFillMode ?? FILL_MODE.NONE; }
  @dependentKeyCompat get fillColumnIndex() { return this.args.fillColumnIndex; }
  @dependentKeyCompat get resizeMode() { return this.args.resizeMode ?? RESIZE_MODE.STANDARD; }
  @dependentKeyCompat get widthConstraint() { return this.args.widthConstraint ?? WIDTH_CONSTRAINT.NONE; }
  @dependentKeyCompat get containerWidthAdjustment() { return this.args.containerWidthAdjustment; }
  @dependentKeyCompat get enableSort() { return Boolean(this.args.onUpdateSorts); }
  @dependentKeyCompat get enableResize() { return this.args.enableResize ?? true; }
  @dependentKeyCompat get enableReorder() { return this.args.enableReorder ?? true; }

  get sortFunction() { return this.args.sortFunction ?? sortMultiple; }
  get compareFunction() { return this.args.compareFunction ?? compareValues; }
  get sortEmptyLast() { return this.args.sortEmptyLast ?? false; }
  get scrollIndicators() { return this.args.scrollIndicators ?? false; }

  get wrappedRowsCount() {
    return isTestingThead ? this.wrappedRows.length : null;
  }

  @cached
  get wrappedRows() {
    let rows = this.columnTree.rows;
    let head = this;

    return emberA(
      rows.map((row, index) => {
        let rowMeta = this.rowMetaCache.get(row);
        if (!rowMeta) {
          rowMeta = EmberObject.create();
          this.rowMetaCache.set(row, rowMeta);
        }
        rowMeta.set('index', index);

        let cells = emberA(
          row.map(columnValue => ({
            columnValue,
            columnMeta: this.columnMetaCache.get(columnValue),
            rowMeta,
            get sorts() {
              return head.sorts;
            },
            sendUpdateSort: this.sendUpdateSort,
          }))
        );

        return { cells, rowMeta, rowsCount: rows.length, isHeader: true };
      })
    );
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
    assert(
      'if columnKeyPath is specified, no two columns can share the same key',
      present.uniq().length === present.length
    );
  }

  @action
  setup(element) {
    this._container = closest(element, '.ember-table-overflow');
    this.columnTree.registerContainer(this._container);
    this.columnTree.performInitialLayout();
    this._tableResizeSensor = new ResizeSensor(this._container, this.fillupHandler);
  }

  @action
  columnsDidChange() {
    this.validateUniqueColumnKeys();
    this.columnMetaCache.keyPath = this.args.columnKeyPath;

    if (get(this.columns, 'length') > 0) {
      this.fillupHandler();
    }
  }

  @action
  sendUpdateSort(sorts) {
    this.args.onUpdateSorts?.(sorts);
  }

  @action
  fillupHandler() {
    if (!this.isDestroying) {
      this.columnTree.ensureWidthConstraint();
    }
  }

  teardown() {
    this.unwrappedApi.unregisterHead(this);
    this._tableResizeSensor?.detach(this._container);
    this.columnTree.destroy();

    for (let cache of [this.columnMetaCache, this.rowMetaCache]) {
      for (let [key, meta] of cache.entries()) {
        meta.destroy();
        cache.delete(key);
      }
    }
  }

  <template>
    <thead
      ...attributes
      data-test-row-count={{this.wrappedRowsCount}}
      {{didInsert this.setup}}
      {{didUpdate this.columnsDidChange this.columnTree.leaves @columnKeyPath}}
    >
      {{#each this.wrappedRows as |api|}}
        {{#if (has-block)}}
          {{yield (hash
            cells=api.cells
            isHeader=api.isHeader
            rowsCount=api.rowsCount
            row=(component EmberTr api=api)
          )}}
        {{else}}
          <EmberTr @api={{api}} />
        {{/if}}
      {{/each}}
    </thead>
  </template>
}
