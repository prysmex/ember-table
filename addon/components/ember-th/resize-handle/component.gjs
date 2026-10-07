import Component from '@glimmer/component';

export default class EmberThResizeHandle extends Component {
  get isResizable() {
    return this.args.columnMeta?.isResizable;
  }

  <template>
    {{#if this.isResizable}}
      <div data-test-resize-handle class="et-header-resize-area"></div>
    {{/if}}
  </template>
}
