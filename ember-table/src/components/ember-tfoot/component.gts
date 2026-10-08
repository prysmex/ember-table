import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import TableSection, { type TableSectionArgs } from '../-private/table-section.ts';
import RowWrapper from '../-private/row-wrapper.gts';
import EmberTr from '../ember-tr/component.gts';
import type { CellApi, RowApi, SelectionMode } from '../../-private/types.ts';
import type { EmberTableColumn, EmberTableRow, TableRowMeta } from '../../index.ts';

export interface EmberTfootSignature<
  RowType extends EmberTableRow = EmberTableRow,
  ColumnType extends EmberTableColumn = EmberTableColumn,
> {
  Element: HTMLTableSectionElement;
  Args: TableSectionArgs<RowType> & { class?: string };
  Blocks: {
    default: [
      {
        api: RowApi<RowType, ColumnType>;
        cells: CellApi<RowType, ColumnType>[];
        row: WithBoundArgs<typeof EmberTr<RowApi<RowType, ColumnType>>, 'api'>;
        rowMeta: TableRowMeta;
        rowValue: RowType;
        rowsCount: number;
        rowSelectionMode: SelectionMode;
      },
    ];
  };
}

export default class EmberTfoot<
  RowType extends EmberTableRow = EmberTableRow,
  ColumnType extends EmberTableColumn = EmberTableColumn,
> extends TableSection<RowType, ColumnType, EmberTfootSignature<RowType, ColumnType>> {
  // Footers render every row, so the collapse tree is flattened directly
  // instead of going through the virtualized collection.
  @cached
  get wrappedRowArray() {
    let tree = this.collapseTree;
    let rows: RowType[] = [];
    for (let i = 0; i < tree.length; i++) {
      rows.push(tree.objectAt(i) as RowType);
    }
    return rows;
  }

  // See `asRow` in `ember-tbody`.
  asRow = (row: object) => row as WithBoundArgs<typeof EmberTr<RowApi<RowType, ColumnType>>, 'api'>;

  <template>
    <tfoot ...attributes data-test-row-count={{this.dataTestRowCount}}>
      {{#each this.wrappedRowArray as |rowValue|}}
        <RowWrapper
          @rowValue={{rowValue}}
          @columns={{this.columns}}
          @columnMetaCache={{this.columnMetaCache}}
          @rowMetaCache={{this.rowMetaCache}}
          @canSelect={{this.canSelect}}
          @rowSelectionMode={{this.rowSelectionMode}}
          @checkboxSelectionMode={{this.checkboxSelectionMode}}
          @rowsCount={{this.wrappedRowArray.length}}
          as |api|
        >
          {{#if (has-block)}}
            {{yield
              (hash
                api=api
                rowValue=api.rowValue
                rowMeta=api.rowMeta
                cells=api.cells
                rowSelectionMode=api.rowSelectionMode
                rowsCount=api.rowsCount
                row=(this.asRow (component EmberTr api=api))
              )
            }}
          {{else}}
            <EmberTr @api={{api}} />
          {{/if}}
        </RowWrapper>
      {{/each}}
    </tfoot>
  </template>
}
