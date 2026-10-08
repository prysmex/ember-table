import { fn } from '@ember/helper';
import { render, settled } from '@ember/test-helpers';
import { EmberTable, EmberTbody, EmberTd, EmberTfoot, EmberTh, EmberThead, EmberTr } from 'ember-table';
import {
  configureTableGeneration,
  generateColumns,
  generateRows,
  resetTableGenerationConfig,
} from 'test-app/utils/generators';

// reexport for use in tests
export { configureTableGeneration, resetTableGenerationConfig, generateColumns, generateRows };

// Renders a full table whose arguments are the test context's properties. The
// template reads them from the context object, so `this.set(...)` in a test
// re-renders as before.
function fullTable(ctx) {
  return <template>
  <div style="height: 500px;">
    <EmberTable data-test-main-table as |t|>
      <EmberThead
        @api={{t}}
        @columns={{ctx.columns}}
        @columnKeyPath={{ctx.columnKeyPath}}
        @containerWidthAdjustment={{ctx.containerWidthAdjustment}}
        @enableReorder={{ctx.enableReorder}}
        @enableResize={{ctx.enableResize}}
        @scrollIndicators={{ctx.scrollIndicators}}
        @fillColumnIndex={{ctx.fillColumnIndex}}
        @fillMode={{ctx.fillMode}}
        @initialFillMode={{ctx.initialFillMode}}
        @resizeMode={{ctx.resizeMode}}
        @sorts={{ctx.sorts}}
        @sortEmptyLast={{ctx.sortEmptyLast}}
        @widthConstraint={{ctx.widthConstraint}}
        @onUpdateSorts={{ctx.onUpdateSorts}}
        @onReorder={{ctx.onReorder}}
        @onResize={{ctx.onResize}}

        as |h|
      >
        <EmberTr @api={{h}} as |r|>
          <EmberTh
            @api={{r}}
            @onContextMenu={{ctx.onHeaderCellContextMenu}}
            @class={{if r.columnMeta.isResizing "is-resizing"}}
          />
        </EmberTr>
      </EmberThead>

      <EmberTbody
        @api={{t}}
        @rows={{ctx.rows}}
        @estimateRowHeight={{ctx.estimateRowHeight}}
        @staticHeight={{ctx.staticHeight}}
        @enableCollapse={{ctx.enableCollapse}}
        @enableTree={{ctx.enableTree}}
        @key={{ctx.key}}
        @bufferSize={{ctx.bufferSize}}
        @idForFirstItem={{ctx.idForFirstItem}}
        @onSelect={{ctx.onSelect}}
        @selectingChildrenSelectsParent={{ctx.selectingChildrenSelectsParent}}
        @checkboxSelectionMode={{ctx.checkboxSelectionMode}}
        @rowSelectionMode={{ctx.rowSelectionMode}}
        @rowToggleMode={{ctx.rowToggleMode}}
        @selection={{ctx.selection}}
        @selectionMatchFunction={{ctx.selectionMatchFunction}}
        as |b|
      >
        <ctx.rowComponent
          @api={{b}}
          @onClick={{fn ctx.onRowClick}}
          @onDoubleClick={{fn ctx.onRowDoubleClick}}
          as |r|
        >
          <EmberTd
            @api={{r}}
            @onClick={{ctx.onCellClick}}
            @onDoubleClick={{ctx.onCellDoubleClick}}
            @class={{if r.columnMeta.isResizing "is-resizing"}}
            as |value|
          >
            {{value}}
          </EmberTd>
        </ctx.rowComponent>
      </EmberTbody>

      <EmberTfoot
        @api={{t}}
        @rows={{ctx.footerRows}}
        as |f|
      >
        <EmberTr @api={{f}} as |r|>
          <EmberTd @api={{r}} as |value|>
            {{value}}
          </EmberTd>
        </EmberTr>
      </EmberTfoot>
    </EmberTable>
  </div>
</template>;
}

const defaultActions = {
  onSelect(newRows) {
    this.set('selection', newRows);
  },

  onUpdateSorts(sorts) {
    this.set('sorts', sorts);
  },

  onDropdownAction() {},
  onColumnHeaderAction() {},
  onHeaderCellContextMenu() {},
  onReorder() {},
  onResize() {},

  onCellClick() {},
  onCellDoubleClick() {},

  onRowClick() {},
  onRowDoubleClick() {},
};

export function generateTableValues(
  testContext,
  {
    rows,
    footerRows,
    columns,
    rowCount = 10,
    rowDepth = 1,
    footerRowCount = 0,
    columnCount = 10,
    columnOptions,

    rowComponent = EmberTr,

    ...options
  } = {}
) {
  for (let property in options) {
    testContext.set(property, options[property]);
  }
  testContext.set('rowComponent', rowComponent);

  columns = columns || generateColumns(columnCount, columnOptions);

  rows = rows || generateRows(rowCount, rowDepth, (row, key) => `${row.id}${key}`);
  footerRows = footerRows || generateRows(footerRowCount, (row, key) => `${row.id}${key}`);

  testContext.set('columns', columns);
  testContext.set('rows', rows);
  testContext.set('footerRows', footerRows);

  for (let action in defaultActions) {
    if (!testContext[action]) {
      testContext.set(action, defaultActions[action].bind(testContext));
    }
  }
}

export async function generateTable(testContext, ...args) {
  generateTableValues(testContext, ...args);

  await render(fullTable(testContext));

  // eslint-disable-next-line ember/no-settled-after-test-helper
  await settled();
}
