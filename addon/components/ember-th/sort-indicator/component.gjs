import Component from '@glimmer/component';

export default class EmberThSortIndicator extends Component {
  get columnMeta() {
    return this.args.columnMeta;
  }

  get isSortable() {
    return this.columnMeta?.isSortable;
  }

  get isSorted() {
    return this.columnMeta?.isSorted;
  }

  get isSortedAsc() {
    return this.columnMeta?.isSortedAsc;
  }

  get isMultiSorted() {
    return this.columnMeta?.isMultiSorted;
  }

  get sortIndex() {
    return this.columnMeta?.sortIndex;
  }

  <template>
    {{#if @columnMeta.isSorted}}
      <span
        data-test-sort-indicator
        class="et-sort-indicator {{if @columnMeta.isSortedAsc 'is-ascending' 'is-descending'}}"
      >
        {{#if (has-block)}}
          {{yield this.columnMeta}}
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
  </template>
}
