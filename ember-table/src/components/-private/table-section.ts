import Component from '@glimmer/component';
import { readOnly } from '@ember/object/computed';
import { dependentKeyCompat } from '@ember/object/compat';
import { assert } from '@ember/debug';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import CollapseTree from '../../-private/collapse-tree';
import { unwrapApi, type TableApiArg } from '../../-private/unwrap-api.ts';
import type {
  CollapseTree as CollapseTreeShape,
  RowMeta,
  SelectionMode,
} from '../../-private/types.ts';
import type { EmberTableColumn, EmberTableRow, EmberTableSort } from '../../index.ts';

let setupRowCountForTest = false;
export function setSetupRowCountForTest(value: boolean) {
  setupRowCountForTest = value;
}

const EMPTY: readonly never[] = Object.freeze([]);

/** Passed to `onSelect`; `abort()` keeps the next range selection anchored. */
export interface SelectionDetails {
  abort(): void;
}

/** Arguments shared by the table's row sections (`<EmberTbody>`, `<EmberTfoot>`). */
export interface TableSectionArgs<RowType extends EmberTableRow> {
  api: TableApiArg;
  rows: RowType[];
  enableCollapse?: boolean;
  enableTree?: boolean;
  selection?: RowType[] | RowType | null;
  selectionMatchFunction?: (selection: RowType, row: RowType) => boolean;
  selectingChildrenSelectsParent?: boolean;
  onSelect?: (rows: RowType[] | RowType, details: SelectionDetails) => void;
  checkboxSelectionMode?: SelectionMode;
  rowSelectionMode?: SelectionMode;
}

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
}) as unknown as { create(properties: Record<string, unknown>): CollapseTreeShape };

/**
  A row section of the table. Its collapse tree derives rows, sorting and
  selection from the section's arguments and the header.
*/
export default abstract class TableSection<
  RowType extends EmberTableRow,
  ColumnType extends EmberTableColumn,
  Signature extends { Args: TableSectionArgs<RowType> },
> extends Component<Signature> {
  rowMetaCache = new Map<RowType, RowMeta>();
  collapseTree: CollapseTreeShape;

  constructor(owner: Owner, args: Signature['Args']) {
    super(owner, args);

    assert(
      'You must create an <EmberThead /> with columns before creating a table body or footer',
      Boolean(this.unwrappedApi.columnTree)
    );

    this.collapseTree = BodyCollapseTree.create({
      _body: this,
      rowMetaCache: this.rowMetaCache,
      onSelect: (selection: RowType[] | RowType, details: SelectionDetails) =>
        this.args.onSelect?.(selection, details),
    });

    registerDestructor(this, () => this.teardown());
  }

  get unwrappedApi() {
    return unwrapApi(this.args.api)!;
  }

  @dependentKeyCompat get rows(): readonly RowType[] {
    return this.args.rows ?? EMPTY;
  }

  @dependentKeyCompat get sorts(): readonly EmberTableSort[] {
    return this.unwrappedApi.sorts ?? EMPTY;
  }

  @dependentKeyCompat get sortFunction() {
    return this.unwrappedApi.sortFunction;
  }

  @dependentKeyCompat get compareFunction() {
    return this.unwrappedApi.compareFunction;
  }

  @dependentKeyCompat get sortEmptyLast() {
    return this.unwrappedApi.sortEmptyLast;
  }

  @dependentKeyCompat get enableCollapse(): boolean {
    return this.args.enableCollapse ?? true;
  }

  @dependentKeyCompat get enableTree(): boolean {
    return this.args.enableTree ?? true;
  }

  @dependentKeyCompat get selection(): RowType[] | RowType | null | undefined {
    return this.args.selection;
  }

  @dependentKeyCompat get selectionMatchFunction(): TableSectionArgs<RowType>['selectionMatchFunction'] {
    return this.args.selectionMatchFunction;
  }

  @dependentKeyCompat get selectingChildrenSelectsParent(): boolean {
    return this.args.selectingChildrenSelectsParent ?? true;
  }

  get columns() {
    return this.unwrappedApi.columnTree!.leaves as ColumnType[];
  }

  get columnMetaCache() {
    return this.unwrappedApi.columnTree!.columnMetaCache;
  }

  get checkboxSelectionMode(): SelectionMode {
    return this.args.checkboxSelectionMode ?? 'multiple';
  }

  get rowSelectionMode(): SelectionMode {
    return this.args.rowSelectionMode ?? 'multiple';
  }

  get canSelect() {
    return Boolean(this.args.onSelect);
  }

  get dataTestRowCount() {
    return setupRowCountForTest ? this.collapseTree.length : null;
  }

  teardown() {
    for (let [row, meta] of this.rowMetaCache) {
      meta.destroy();
      this.rowMetaCache.delete(row);
    }
    this.collapseTree.destroy();
  }
}
