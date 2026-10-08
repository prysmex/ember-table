import Component from '@glimmer/component';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { didInsert, didUpdate, willDestroy } from '@ember/render-modifiers';
import {
  setupTableStickyPolyfill,
  teardownTableStickyPolyfill,
} from '../../-private/sticky/table-sticky-polyfill';
import ScrollIndicators, { ScrollIndicatorTracker } from '../-private/scroll-indicators/component';
import EmberThead from '../ember-thead/component';
import EmberTbody from '../ember-tbody/component';
import EmberTfoot from '../ember-tfoot/component';
import EmberTableLoadingMore from '../ember-table-loading-more/component';
import TableApi from '../../-private/table-api';

export default class EmberTable extends Component {
  tableId = `${guidFor(this)}-overflow`;
  api = new TableApi(this.tableId);
  scrollIndicators = new ScrollIndicatorTracker(this.api);

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
      ...attributes
      class="ember-table {{@class}}"
      data-test-ember-table
      {{didInsert this.setup}}
      {{willDestroy this.teardown}}
    >
      <div
        data-test-ember-table-overflow
        class="ember-table-overflow"
        id={{this.tableId}}
        {{didInsert this.scrollIndicators.attach}}
        {{didUpdate this.scrollIndicators.sync this.api.scrollIndicators}}
        {{willDestroy this.scrollIndicators.detach}}
      >
        <table>
          {{yield (hash
            api=this.api
            head=(component EmberThead api=this.api)
            body=(component EmberTbody api=this.api)
            foot=(component EmberTfoot api=this.api)
            loadingMore=(component EmberTableLoadingMore api=this.api)
          )}}
        </table>
      </div>
      <ScrollIndicators @api={{this.api}} @tracker={{this.scrollIndicators}} />
    </div>
  </template>
}
