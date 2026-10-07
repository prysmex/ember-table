import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { next } from '@ember/runloop';
import { action, get } from '@ember/object';
import { assert } from '@ember/debug';
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
    this.collapseTree = CollapseTree.create({
      rows: this.args.rows ?? [],
      onSelect: (...args) => {
        this.args.onSelect?.(...args);
        this.selectionRevision++;
        next(this, this.syncModels);
      },
      rowMetaCache: this.rowMetaCache,
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
    this._lastSelection = this.args.selection;
    registerDestructor(this, () => this.teardown());
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
    if (this.args.selection !== this._lastSelection) {
      this._lastSelection = this.args.selection;
      this.selectionRevision++;
    }
    this.collapseTree.setProperties({
      rowMetaCache: this.rowMetaCache,
      rows: this.args.rows ?? [],
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
  }

  get wrappedRows() {
    return this.collapseTree;
  }

  teardown() {
    for (let [row, meta] of this.rowMetaCache) {
      meta.destroy();
      this.rowMetaCache.delete(row);
    }
    this.collapseTree.destroy();
  }

  <template>
    <tbody ...attributes data-test-row-count={{this.dataTestRowCount}} data-selection={{this.args.selection}} data-selection-revision={{this.selectionRevision}} {{didUpdate this.syncModels}}>
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
