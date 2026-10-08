import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import { closest } from '../../-private/utils/element';
import { SELECT_MODE } from '../../-private/collapse-tree';
import EmberTh from '../ember-th/component.gts';
import EmberTd from '../ember-td/component.gts';
import type {
  CellValue,
  EmberTableColumn,
  EmberTableRow,
  TableColumnMeta,
  TableRowMeta,
} from '../../index.ts';
import type { CellApi, HeaderRowApi, RowApi } from '../../-private/types.ts';

const SELECTABLE_MODES: readonly string[] = [SELECT_MODE.MULTIPLE, SELECT_MODE.SINGLE];

export interface EmberTrEvent<RowType> {
  event: MouseEvent;
  rowValue: RowType | undefined;
  rowMeta: TableRowMeta | undefined;
}

export interface EmberTrSignature<
  RowType extends EmberTableRow = EmberTableRow,
  ColumnType extends EmberTableColumn = EmberTableColumn,
  CellComponentType = WithBoundArgs<typeof EmberTd<RowType, ColumnType>, 'api'>,
> {
  Element: HTMLTableRowElement;
  Args: {
    /** @internal Provided by the yielded `row` component, or pass the section's yield. */
    api: RowApi<RowType, ColumnType> | HeaderRowApi<ColumnType>;
    class?: string;
    /** Called when the row is clicked. */
    onClick?: (event: EmberTrEvent<RowType>) => void;
    /** Called when the row is double clicked. */
    onDoubleClick?: (event: EmberTrEvent<RowType>) => void;
  };
  Blocks: {
    default: [
      {
        api: CellApi<RowType, ColumnType>;
        cell: CellComponentType;
        cellMeta: unknown;
        cellValue: CellValue<RowType>;
        columnMeta: TableColumnMeta;
        columnValue: ColumnType;
        rowMeta: TableRowMeta;
        rowValue: RowType;
        rowsCount: number;
      },
    ];
  };
}

export default class EmberTr<
  RowType extends EmberTableRow = EmberTableRow,
  ColumnType extends EmberTableColumn = EmberTableColumn,
  CellComponentType = WithBoundArgs<typeof EmberTd<RowType, ColumnType>, 'api'>,
> extends Component<EmberTrSignature<RowType, ColumnType, CellComponentType>> {
  // The cell component is picked at runtime (header or body row), while
  // `CellComponentType` describes it to consumers; this is the one place the
  // yielded hash is asserted to match the signature.
  asCellYield = (cell: object) =>
    cell as EmberTrSignature<RowType, ColumnType, CellComponentType>['Blocks']['default'][0];

  get api() {
    return this.args.api;
  }

  get headerApi(): HeaderRowApi<ColumnType> | undefined {
    let api = this.api;
    return api.isHeader ? api : undefined;
  }

  get bodyApi(): RowApi<RowType, ColumnType> | undefined {
    let api = this.api;
    return api.isHeader ? undefined : api;
  }

  get customClass() {
    return this.args.class ?? '';
  }

  get rowMeta() {
    return this.api.rowMeta;
  }

  get isSelected() {
    return this.bodyApi?.rowMeta.isSelected;
  }

  get isGroupSelected() {
    return this.bodyApi?.rowMeta.isGroupSelected;
  }

  get isEven() {
    return (this.rowMeta?.index ?? 0) % 2 === 0;
  }

  get isSelectable() {
    return SELECTABLE_MODES.includes(this.bodyApi?.rowSelectionMode ?? '');
  }

  @action
  click(event: MouseEvent) {
    let row = this.bodyApi;
    let inputParent = closest(event.target, 'input, button, label, a, select') as Element | null;

    if (row && !inputParent) {
      if (row.rowSelectionMode === SELECT_MODE.MULTIPLE) {
        row.rowMeta.select({
          toggle: event.ctrlKey || event.metaKey || row.rowToggleMode,
          range: event.shiftKey,
        });
      } else if (row.rowSelectionMode === SELECT_MODE.SINGLE) {
        row.rowMeta.select({ single: true });
      }
    }

    this.sendEventAction(this.args.onClick, event);
  }

  @action
  doubleClick(event: MouseEvent) {
    this.sendEventAction(this.args.onDoubleClick, event);
  }

  sendEventAction(callback: ((event: EmberTrEvent<RowType>) => void) | undefined, event: MouseEvent) {
    let row = this.bodyApi;
    callback?.({ event, rowValue: row?.rowValue, rowMeta: row?.rowMeta });
  }

  <template>
    <tr
      ...attributes
      class="et-tr {{this.customClass}}
        {{if this.isEven 'is-even' 'is-odd'}}
        {{if this.isGroupSelected 'is-group-selected'}}
        {{if this.isSelectable 'is-selectable'}}
        {{if this.isSelected 'is-selected'}}"
      {{on "click" this.click}}
      {{on "dblclick" this.doubleClick}}
    >
      {{#if this.headerApi}}
        {{#each this.headerApi.cells as |api|}}
          {{#if (has-block)}}
            {{yield
              (this.asCellYield
                (hash
                  columnValue=api.columnValue
                  columnMeta=api.columnMeta
                  sorts=api.sorts
                  sendUpdateSort=api.sendUpdateSort
                  rowMeta=api.rowMeta
                  rowsCount=this.headerApi.rowsCount
                  cell=(component EmberTh api=api)
                )
              )
            }}
          {{else}}
            <EmberTh @api={{api}} />
          {{/if}}
        {{/each}}
      {{else if this.bodyApi}}
        {{#each this.bodyApi.cells as |api|}}
          {{#if (has-block)}}
            {{yield
              (this.asCellYield
                (hash
                  api=api
                  cellValue=api.cellValue
                  cellMeta=api.cellMeta
                  columnValue=api.columnValue
                  columnMeta=api.columnMeta
                  rowValue=api.rowValue
                  rowMeta=api.rowMeta
                  rowsCount=api.rowsCount
                  cell=(component EmberTd api=api)
                )
              )
            }}
          {{else}}
            <EmberTd @api={{api}} />
          {{/if}}
        {{/each}}
      {{/if}}
    </tr>
  </template>
}
