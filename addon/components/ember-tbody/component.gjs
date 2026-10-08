import Component from '@glimmer/component';
import { readOnly } from '@ember/object/computed';
import { dependentKeyCompat } from '@ember/object/compat';
import { assert } from '@ember/debug';
import { registerDestructor } from '@ember/destroyable';
import { VerticalCollection } from '@html-next/vertical-collection';
import CollapseTree, { SELECT_MODE } from '../../-private/collapse-tree';
import RowWrapper from '../-private/row-wrapper';
import EmberTr from '../ember-tr/component';

let setupRowCountForTest = false;
export function setSetupRowCountForTest(value) {
  setupRowCountForTest = value;
}

const EMPTY = Object.freeze([]);

// See `HeadColumnTree` in `ember-thead`: the collapse tree derives its inputs
// from the body's getters instead of having them pushed in on every change.
const BodyCollapseTree = CollapseTree.extend({
  rows: readOnly('_body.rows'),
  sorts: readOnly('_body.sorts'),
  sortFunction: readOnly('_body.sortFunction'),
  compareFunction: readOnly('_body.compareFunction'),
  sortEmptyLast: readOnly('_body.sortEmptyLast'),
  enableCollapse: readOnly('_body.enableCollapse'),
  enableTree: readOnly('_body.enableTree'),
  selection: readOnly('_body.selection'),
  selectionMatchFunction: readOnly('_body.selectionMatchFunction'),
  selectingChildrenSelectsParent: readOnly('_body.selectingChildrenSelectsParent'),
});

export default class EmberTbody extends Component {
  rowMetaCache = new Map();

  constructor(owner, args) {
    super(owner, args);

    assert(
      'You must create an <EmberThead /> with columns before creating an <EmberTbody />',
      Boolean(this.unwrappedApi?.columnTree)
    );

    this.collapseTree = BodyCollapseTree.create({
      _body: this,
      rowMetaCache: this.rowMetaCache,
      onSelect: (...values) => this.args.onSelect?.(...values),
    });

    registerDestructor(this, () => this.teardown());
  }

  get unwrappedApi() {
    return this.args.api?.api ?? this.args.api;
  }

  @dependentKeyCompat get rows() { return this.args.rows ?? EMPTY; }
  @dependentKeyCompat get sorts() { return this.unwrappedApi.sorts ?? EMPTY; }
  @dependentKeyCompat get sortFunction() { return this.unwrappedApi.sortFunction; }
  @dependentKeyCompat get compareFunction() { return this.unwrappedApi.compareFunction; }
  @dependentKeyCompat get sortEmptyLast() { return this.unwrappedApi.sortEmptyLast; }
  @dependentKeyCompat get enableCollapse() { return this.args.enableCollapse ?? true; }
  @dependentKeyCompat get enableTree() { return this.args.enableTree ?? true; }
  @dependentKeyCompat get selection() { return this.args.selection; }
  @dependentKeyCompat get selectionMatchFunction() { return this.args.selectionMatchFunction; }
  @dependentKeyCompat get selectingChildrenSelectsParent() {
    return this.args.selectingChildrenSelectsParent ?? true;
  }

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

  teardown() {
    for (let [row, meta] of this.rowMetaCache) {
      meta.destroy();
      this.rowMetaCache.delete(row);
    }
    this.collapseTree.destroy();
  }

  <template>
    <tbody ...attributes data-test-row-count={{this.dataTestRowCount}}>
      <VerticalCollection
        @items={{this.collapseTree}}
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
            @rowsCount={{this.collapseTree.length}}
            as |api|
          >
            {{#if (has-block)}}
              {{yield (hash
                rowValue=api.rowValue
                rowMeta=api.rowMeta
                cells=api.cells
                rowSelectionMode=api.rowSelectionMode
                rowToggleMode=api.rowToggleMode
                rowsCount=api.rowsCount
                row=(component EmberTr api=api)
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
