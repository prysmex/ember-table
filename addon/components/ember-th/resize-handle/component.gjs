import Component from '@glimmer/component';

export default class EmberThResizeHandle extends Component {
  <template>
    {{#if @columnMeta.isResizable}}
      <div data-test-resize-handle class="et-header-resize-area"></div>
    {{/if}}
  </template>
}
