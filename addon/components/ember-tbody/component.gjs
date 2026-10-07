import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { next } from '@ember/runloop';
import { action, get } from '@ember/object';
import { assert } from '@ember/debug';
import { notifyPropertyChange } from '../../-private/utils/ember';
import { registerDestructor } from '@ember/destroyable';
import { didUpdate } from '@ember/render-modifiers';
import { VerticalCollection } from '@html-next/vertical-collection';
import CollapseTree, { SELECT_MODE } from '../../-private/collapse-tree';
import RowWrapper from '../-private/row-wrapper';
import EmberTr from '../ember-tr/component';

let setupRowCountForTest = false;
export function setSetupRowCountForTest(value) { setupRowCountForTest = value; }

export default class EmberTbody extends Component {
  @tracked selectionRevision = 0;
  rowMetaCache = new Map();

  constructor(owner, args) {
    super(owner, args);
    assert(
      'You must create an <EmberThead /> with columns before creating an <EmberTbody />',
      Boolean(this.unwrappedApi?.columnTree)
    );
    this.collapseTree = this.createCollapseTree();
    if (this.constructor === EmberTbody) {
      this.unwrappedApi.registerBody?.(this);
    }
    this._rows = this.args.rows ?? [];
    this._sortSignature = this.sortSignature;
    registerDestructor(this, () => this.teardown());
  }

  get sortSignature() {
    return (this.unwrappedApi.sorts ?? []).map(sort => `${get(sort, 'valuePath')}:${get(sort, 'isAscending')}`).join('|');
  }

  createCollapseTree(sorts = this.unwrappedApi.sorts) {
    return CollapseTree.create({
      rows: this.args.rows ?? [],
      onSelect: (...args) => {
        this.args.onSelect?.(...args);
        this.selectionRevision++;
        next(this, this.syncModels);
      },
      rowMetaCache: this.rowMetaCache,
      sorts,
      sortFunction: this.unwrappedApi.sortFunction,
      compareFunction: this.unwrappedApi.compareFunction,
      sortEmptyLast: this.unwrappedApi.sortEmptyLast,
      enableCollapse: this.args.enableCollapse ?? true,
      enableTree: this.args.enableTree ?? true,
      selection: this.args.selection,
      selectionMatchFunction: this.args.selectionMatchFunction,
      selectingChildrenSelectsParent: this.args.selectingChildrenSelectsParent ?? true,
    });
  }

  updateSorts(sorts) {
    this._sortSignature = sorts.map(sort => `${get(sort, 'valuePath')}:${get(sort, 'isAscending')}`).join('|');
    this.collapseTree.set('sorts', sorts);
    notifyPropertyChange(this.collapseTree, 'sorts');
    notifyPropertyChange(this.collapseTree, '[]');
  }

  get unwrappedApi() { return this.args.api?.api ?? this.args.api; }
  get columns() { return this.unwrappedApi.columnTree.leaves; }
  get columnMetaCache() { return this.unwrappedApi.columnTree.columnMetaCache; }
  get checkboxSelectionMode() { return this.args.checkboxSelectionMode ?? SELECT_MODE.MULTIPLE; }
  get rowSelectionMode() { return this.args.rowSelectionMode ?? SELECT_MODE.MULTIPLE; }
  get rowToggleMode() { return this.args.rowToggleMode ?? false; }
  get canSelect() { return Boolean(this.args.onSelect); }
  get estimateRowHeight() { return this.args.estimateRowHeight ?? 30; }
  get staticHeight() { return this.args.staticHeight ?? false; }
  get bufferSize() { return this.args.bufferSize ?? 1; }
  get renderAll() { return this.args.renderAll ?? false; }
  get key() { return this.args.key ?? '@identity'; }
  get containerSelector() { return this.args.containerSelector || `#${this.unwrappedApi.tableId}`; }
  get dataTestRowCount() { return setupRowCountForTest ? this.collapseTree.length : null; }

  @action
  syncModels() {
    let rows = this.args.rows ?? [];
    let sortSignature = this.sortSignature;
    if (rows !== this._rows || sortSignature !== this._sortSignature) {
      this._rows = rows;
      this._sortSignature = sortSignature;
    }
    if (this.args.selection !== this._lastSelection) {
      this._lastSelection = this.args.selection;
      this.selectionRevision++;
    }
    this.collapseTree.setProperties({
      rowMetaCache: this.rowMetaCache,
      rows,
      sorts: this.unwrappedApi.sorts,
      sortFunction: this.unwrappedApi.sortFunction,
      compareFunction: this.unwrappedApi.compareFunction,
      sortEmptyLast: this.unwrappedApi.sortEmptyLast,
      enableCollapse: this.args.enableCollapse ?? true,
      enableTree: this.args.enableTree ?? true,
      selection: this.args.selection,
      selectionMatchFunction: this.args.selectionMatchFunction,
      selectingChildrenSelectsParent: this.args.selectingChildrenSelectsParent ?? true,
    });
    // The host application commonly mutates EmberArrays in place (sorting,
    // selection, or changing rows).  Setting the same array reference does not
    // invalidate the classic computed properties used by CollapseTree, so
    // explicitly notify both the dependent properties and its array facade.
    notifyPropertyChange(this.collapseTree, 'rows');
    notifyPropertyChange(this.collapseTree, 'sorts');
    notifyPropertyChange(this.collapseTree, 'selection');
    notifyPropertyChange(this.collapseTree, 'selectionMatchFunction');
    // Materialize the new root before notifying VerticalCollection. Its Radar
    // reads the collection synchronously from the `items.[]` notification.
    this.collapseTree.get('length');
    notifyPropertyChange(this.collapseTree, '[]');
  }

  get wrappedRows() { return this.collapseTree; }

  teardown() {
    for (let [row, meta] of this.rowMetaCache) {
      meta.destroy();
      this.rowMetaCache.delete(row);
    }
    this.collapseTree.destroy();
  }

  <template>
    <tbody
      ...attributes
      data-test-row-count={{this.dataTestRowCount}}
      data-selection={{this.args.selection}}
      data-selection-revision={{this.selectionRevision}}
      {{didUpdate
        this.syncModels
        this.args.rows
        this.args.selection
        this.args.selectionMatchFunction
        this.args.enableTree
        this.args.enableCollapse
        this.args.selectingChildrenSelectsParent
      }}
    >
      <VerticalCollection
        @items={{this.wrappedRows}}
        @containerSelector={{this.containerSelector}}
        @estimateHeight={{this.estimateRowHeight}}
        @key={{this.key}}
        @staticHeight={{this.staticHeight}}
        @bufferSize={{this.bufferSize}}
        @renderAll={{this.renderAll}}
        @firstReached={{@firstReached}}
        @lastReached={{@lastReached}}
        @firstVisibleChanged={{@firstVisibleChanged}}
        @lastVisibleChanged={{@lastVisibleChanged}}
        @idForFirstItem={{@idForFirstItem}}
      >
        <:default as |rowValue|>
          <RowWrapper
            @rowValue={{rowValue}}
            @columns={{this.columns}}
            @columnMetaCache={{this.columnMetaCache}}
            @rowMetaCache={{this.rowMetaCache}}
            @canSelect={{this.canSelect}}
            @checkboxSelectionMode={{this.checkboxSelectionMode}}
            @rowSelectionMode={{this.rowSelectionMode}}
            @rowToggleMode={{this.rowToggleMode}}
            @selection={{this.args.selection}}
            @selectionMatchFunction={{this.args.selectionMatchFunction}}
            @rowsCount={{this.wrappedRows.length}}
            as |api|
          >
            {{#if (has-block)}}
              {{yield (hash
                rowValue=api.rowValue rowMeta=api.rowMeta cells=api.cells
                rowSelectionMode=api.rowSelectionMode rowToggleMode=api.rowToggleMode
                rowsCount=api.rowsCount row=(component EmberTr api=api)
              )}}
            {{else}}
              <EmberTr @api={{api}} />
            {{/if}}
          </RowWrapper>
        </:default>
        <:inverse>{{yield to="inverse"}}</:inverse>
      </VerticalCollection>
    </tbody>
  </template>
}
