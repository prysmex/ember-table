import type { TOC } from '@ember/component/template-only';
import type { TableColumnMeta } from '../../../index.ts';

export interface ResizeHandleSignature {
  Args: {
    columnMeta: TableColumnMeta;
  };
}

const ResizeHandle: TOC<ResizeHandleSignature> = <template>
  {{#if @columnMeta.isResizable}}
    <div data-test-resize-handle class="et-header-resize-area"></div>
  {{/if}}
</template>;

export default ResizeHandle;
