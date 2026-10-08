import { cached } from '@glimmer/tracking';
import EmberTbody from '../ember-tbody/component';
import RowWrapper from '../-private/row-wrapper';
import EmberTr from '../ember-tr/component';

export default class EmberTfoot extends EmberTbody {
  // Footers render every row, so the collapse tree is flattened directly
  // instead of going through the virtualized collection.
  @cached
  get wrappedRowArray() {
    let tree = this.collapseTree;
    let rows = [];
    for (let i = 0; i < tree.length; i++) {
      rows.push(tree.objectAt(i));
    }
    return rows;
  }

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
            {{yield (hash
              rowValue=api.rowValue
              rowMeta=api.rowMeta
              cells=api.cells
              rowSelectionMode=api.rowSelectionMode
              rowsCount=api.rowsCount
              row=(component EmberTr api=api)
            )}}
          {{else}}
            <EmberTr @api={{api}} />
          {{/if}}
        </RowWrapper>
      {{/each}}
    </tfoot>
  </template>
}
