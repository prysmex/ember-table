import type { TOC } from '@ember/component/template-only';
import type { TableColumnMeta } from '../../../index.ts';

export interface SortIndicatorSignature {
  Args: {
    columnMeta: TableColumnMeta;
  };
  Blocks: {
    default: [columnMeta: TableColumnMeta];
  };
}

const SortIndicator: TOC<SortIndicatorSignature> = <template>
  {{#if @columnMeta.isSorted}}
    <span
      data-test-sort-indicator
      class="et-sort-indicator {{if @columnMeta.isSortedAsc 'is-ascending' 'is-descending'}}"
    >
      {{#if (has-block)}}
        {{yield @columnMeta}}
      {{else if @columnMeta.isMultiSorted}}
        {{@columnMeta.sortIndex}}
      {{/if}}
    </span>
  {{/if}}

  {{#if @columnMeta.isSortable}}
    <button type="button" data-test-sort-toggle class="et-sort-toggle et-speech-only">
      Toggle Sort
    </button>
  {{/if}}
</template>;

export default SortIndicator;
