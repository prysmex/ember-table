import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { guidFor } from '@ember/object/internals';
import { didInsert, willDestroy } from '@ember/render-modifiers';
import {
  setupTableStickyPolyfill,
  teardownTableStickyPolyfill,
} from '../../-private/sticky/table-sticky-polyfill';
import ScrollIndicators from '../-private/scroll-indicators/component';
import EmberThead from '../ember-thead/component';
import EmberTbody from '../ember-tbody/component';
import EmberTfoot from '../ember-tfoot/component';
import EmberTableLoadingMore from '../ember-table-loading-more/component';

export default class EmberTable extends Component {
  @tracked apiRevision = 0;
  tableId = `${guidFor(this)}-overflow`;
  api = {
    columns: null,
    columnTree: null,
    registerColumnTree: this.registerColumnTree,
    tableId: this.tableId,
    notifyRevision: () => this.notifyRevision(),
    registerBody: body => (this.api.body = body),
  };

  @action
  notifyRevision() {
    this.apiRevision++;
  }

  @action
  registerColumnTree(columnTree) {
    this.api.columnTree = columnTree;
  }

  @action
  setup(element) {
    for (let section of [element.querySelector('thead'), element.querySelector('tfoot')]) {
      if (section) {
        setupTableStickyPolyfill(section);
      }
    }
  }

  @action
  teardown(element) {
    for (let section of [element.querySelector('thead'), element.querySelector('tfoot')]) {
      if (section) {
        teardownTableStickyPolyfill(section);
      }
    }
  }

  <template>
    <div
      class="ember-table"
      data-test-ember-table
      {{didInsert this.setup}}
      {{willDestroy this.teardown}}
    >
      <div data-test-ember-table-overflow class="ember-table-overflow" id={{this.tableId}}>
        <table>
          {{yield (hash
            api=this.api
            revision=this.apiRevision
            head=(component EmberThead api=this.api)
            body=(component EmberTbody api=this.api)
            foot=(component EmberTfoot api=this.api)
            loadingMore=(component EmberTableLoadingMore api=this.api)
          )}}
        </table>
      </div>
      <ScrollIndicators @api={{this.api}} />
    </div>
  </template>
}
