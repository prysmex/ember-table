import { hash } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import { VerticalCollection } from '@html-next/vertical-collection';
import RowWrapper from '../-private/row-wrapper.gts';
import TableSection, { type SelectionDetails } from '../-private/table-section.ts';
import EmberTr from '../ember-tr/component.gts';
import type { TableApiArg } from '../../-private/unwrap-api.ts';
import type { CellApi, SelectionMode } from '../../-private/types.ts';
import type { EmberTableColumn, EmberTableRow, TableRowMeta } from '../../index.ts';

export { setSetupRowCountForTest } from '../-private/table-section.ts';

export interface EmberTbodyArgs<RowType extends EmberTableRow = EmberTableRow> {
  /** @internal The table's API, or the hash `<EmberTable>` yields. */
  api: TableApiArg;

  class?: string;

  /**
   * The number of extra rows to render on either side of the table's viewport.
   */
  bufferSize?: number;

  /**
   * Sets which row selection behavior to follow.
   * Possible values are `none` (clicking on a row does nothing), `single` (clicking on a row selects it and deselects other rows), and `multiple` (multiple rows can be selected through ctrl/cmd-click or shift-click).
   */
  checkboxSelectionMode?: SelectionMode;

  /**
   * A selector string that will select the element from which to calculate the viewable height.
   */
  containerSelector?: string;

  /**
   * Boolean flag that enables collapsing tree nodes.
   */
  enableCollapse?: boolean;

  /**
   * Boolean flag that enables tree behavior if items have a `children` property.
   */
  enableTree?: boolean;

  /**
   * Estimated height for each row.
   * This number is used to decide how many rows will be rendered at initial rendering.
   */
  estimateRowHeight?: number;

  /**
   * Invokes an action when the first row in the table is reached/in view.
   */
  firstReached?: (...args: unknown[]) => void;

  /**
   * An action that is triggered when the first visible row of the table changes.
   */
  firstVisibleChanged?: (...args: unknown[]) => void;

  /**
   * The property is passed through to the vertical-collection.
   * If set, upon initialization the scroll position will be set such that the item with the provided id is at the top left on screen.
   * If the item with id cannot be found, `scrollTop` is set to 0.
   */
  idForFirstItem?: string;

  /**
   * This key is the property used by the collection to determine whether an array mutation is an append, prepend, or complete replacement.
   * It is also the key that is passed to the actions, and can be used to restore scroll position with `idForFirstItem`.
   * This is passed through to the vertical-collection.
   */
  key?: string;

  /**
   * An action that is triggered when the table reaches the last row.
   */
  lastReached?: (...args: unknown[]) => void;

  /**
   * An action that is triggered when the last visible row of the table changes.
   */
  lastVisibleChanged?: (...args: unknown[]) => void;

  /**
   * An action that is called when the row selection of the table changes.
   * Will be called with either an array or individual row, depending on the checkboxSelectionMode.
   */
  onSelect?: (rows: RowType[] | RowType, details: SelectionDetails) => void;

  /**
   * A flag that tells the table to render all of its rows at once.
   */
  renderAll?: boolean;

  /**
   * The row items that the table should display.
   */
  rows: RowType[];

  /**
   * Sets which row selection behavior to follow.
   * Possible values are `none` (clicking on a row does nothing), `single` (clicking on a row selects it and deselects other rows), and `multiple` (multiple rows can be selected through ctrl/cmd-click or shift-click).
   */
  rowSelectionMode?: SelectionMode;

  /**
   * When `true`, this option enables the toggling of rows without using the ctrlKey or metaKey.
   */
  rowToggleMode?: boolean;

  /**
   * When `true`, this option causes selecting all of a node's children to also select the node itself.
   */
  selectingChildrenSelectsParent?: boolean;

  /**
   * The currently selected rows.
   * Can either be an array or an individual row.
   */
  selection?: RowType[] | RowType | null;

  /**
   * A function that will override how selection is compared to row value.
   */
  selectionMatchFunction?: (selection: RowType, row: RowType) => boolean;

  /**
   * A flag that controls if all rows have same static height or not.
   * By default it is set to `false` and row height is dependent on its internal content.
   * If it is set to `true`, all rows have the same height equivalent to `estimateRowHeight`.
   */
  staticHeight?: boolean;
}

export interface EmberTbodySignature<
  RowType extends EmberTableRow = EmberTableRow,
  ColumnType extends EmberTableColumn = EmberTableColumn,
> {
  Element: HTMLTableSectionElement;
  Args: EmberTbodyArgs<RowType>;
  Blocks: {
    default: [
      {
        cells: CellApi<RowType, ColumnType>[];
        row: WithBoundArgs<typeof EmberTr<RowType, ColumnType>, 'api'>;
        rowMeta: TableRowMeta;
        rowValue: RowType;
        rowsCount: number;
        rowSelectionMode: SelectionMode;
        rowToggleMode: boolean | undefined;
      },
    ];
    else: [];
  };
}

export default class EmberTbody<
  RowType extends EmberTableRow = EmberTableRow,
  ColumnType extends EmberTableColumn = EmberTableColumn,
> extends TableSection<RowType, ColumnType, EmberTbodySignature<RowType, ColumnType>> {
  get rowToggleMode() {
    return this.args.rowToggleMode ?? false;
  }

  get estimateRowHeight() {
    return this.args.estimateRowHeight ?? 30;
  }

  get staticHeight() {
    return this.args.staticHeight ?? false;
  }

  get bufferSize() {
    return this.args.bufferSize ?? 1;
  }

  get renderAll() {
    return this.args.renderAll ?? false;
  }

  get key() {
    return this.args.key ?? '@identity';
  }

  get containerSelector() {
    return this.args.containerSelector || `#${this.unwrappedApi.tableId}`;
  }

  // `EmberTr`'s generic parameters describe the rows to consumers; this is
  // the one place the yielded row component is asserted to match.
  asRow = (row: object) => row as WithBoundArgs<typeof EmberTr<RowType, ColumnType>, 'api'>;

  // The virtual collection yields untyped items; they are this body's rows.
  asRowValue = (item: unknown) => item as RowType;

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
            @rowValue={{this.asRowValue rowValue}}
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
              {{yield
                (hash
                  rowValue=api.rowValue
                  rowMeta=api.rowMeta
                  cells=api.cells
                  rowSelectionMode=api.rowSelectionMode
                  rowToggleMode=api.rowToggleMode
                  rowsCount=api.rowsCount
                  row=(this.asRow (component EmberTr api=api))
                )
              }}
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
