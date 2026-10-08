/* global ResizeSensor */
import Component from '@glimmer/component';
import { get } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';

/**
  Measures the table's scroll container. `<EmberTable>` attaches it to the
  overflow element through modifiers, so listeners live exactly as long as the
  element they observe, and `<ScrollIndicators>` only renders the result.
*/
export class ScrollIndicatorTracker {
  @tracked geometry = {};
  element = null;
  _isListening = false;

  constructor(api) {
    this.api = api;
  }

  get enabledIndicators() {
    switch (this.api.scrollIndicators) {
      case true:
      case 'all':
        return ['left', 'right', 'top', 'bottom'];
      case 'horizontal':
        return ['left', 'right'];
      case 'vertical':
        return ['top', 'bottom'];
      default:
        return [];
    }
  }

  attach = element => {
    this.element = element;
    this.sync();
  };

  sync = () => {
    let enabled = this.enabledIndicators.length > 0;
    if (enabled && !this._isListening) this.addListeners();
    else if (!enabled && this._isListening) this.removeListeners();
  };

  detach = () => {
    this.removeListeners();
    this.element = null;
  };

  addListeners() {
    let table = this.element?.querySelector('table');
    if (!table) return;
    this._isListening = true;
    this._table = table;
    this.element.addEventListener('scroll', this.updateIndicators);
    this._tableResizeSensor = new ResizeSensor(table, this.updateIndicators);
    this.updateIndicators();
  }

  removeListeners() {
    if (!this._isListening) return;
    this._isListening = false;
    this.element.removeEventListener('scroll', this.updateIndicators);
    this._tableResizeSensor.detach();
    this.removeFooterListeners();
  }

  addFooterListeners(footer) {
    if (this._footer === footer) return;
    this.removeFooterListeners();
    this._footer = footer;
    this._footerResizeSensor = new ResizeSensor(footer, this.updateIndicators);
    this._footerMutationObserver = new MutationObserver(this.updateIndicators);
    this._footerMutationObserver.observe(footer, {
      subtree: true,
      attributes: true,
      attributeFilter: ['style'],
      childList: true,
    });
  }

  removeFooterListeners() {
    if (!this._footer) return;
    this._footerResizeSensor.detach();
    this._footerMutationObserver.disconnect();
    this._footer = null;
  }

  updateIndicators = () => {
    let element = this.element;
    let table = this._table;
    if (!element || !table) return;

    let visibleFooterHeight = 0;
    let footerCell = table.querySelector('tfoot td');
    if (footerCell) {
      this.addFooterListeners(table.querySelector('tfoot'));
      let rect = element.getBoundingClientRect();
      let scale = element.offsetHeight / rect.height;
      visibleFooterHeight = Math.max(
        0,
        Math.min(
          element.clientHeight - scale * (footerCell.getBoundingClientRect().y - rect.y),
          element.clientHeight
        )
      );
    } else {
      this.removeFooterListeners();
    }

    let { scrollLeft, scrollTop } = element;
    this.geometry = {
      scrollLeft,
      scrollRight: element.scrollWidth - element.clientWidth - scrollLeft,
      scrollTop,
      scrollBottom: element.scrollHeight - element.clientHeight - scrollTop,
      scrollbarWidth: element.offsetWidth - element.clientWidth,
      scrollbarHeight: element.offsetHeight - element.clientHeight,
      overflowHeight: element.clientHeight,
      overflowWidth: element.clientWidth,
      tableWidth: table.offsetWidth,
      tableHeight: table.offsetHeight,
      headerHeight: table.querySelector('thead')?.offsetHeight,
      visibleFooterHeight,
      footerRatio: element.offsetHeight ? visibleFooterHeight / element.offsetHeight : undefined,
    };
  };
}

export default class ScrollIndicators extends Component {
  get geometry() {
    return this.args.tracker.geometry;
  }

  get enabledIndicators() {
    return this.args.tracker.enabledIndicators;
  }

  get showLeft() { return this.enabledIndicators.includes('left') && this.geometry.scrollLeft > 0; }
  get showRight() { return this.enabledIndicators.includes('right') && this.geometry.scrollRight > 0; }
  get showTop() { return this.enabledIndicators.includes('top') && this.geometry.scrollTop > 0; }
  get showBottom() { return this.enabledIndicators.includes('bottom') && this.geometry.scrollBottom > 0; }

  horizontalStyle(side) {
    let fixed = get(this.args.api.columnTree, `${side}FixedNodes`) ?? [];
    let offset = fixed.reduce((sum, node) => sum + get(node, 'width'), 0);
    if (side === 'right') offset += this.geometry.scrollbarWidth || 0;
    let height = Math.min(this.geometry.overflowHeight ?? Infinity, this.geometry.tableHeight ?? Infinity);
    return htmlSafe(`${side}:${offset}px;${Number.isFinite(height) ? `height:${height}px` : ''}`);
  }

  verticalStyle(side) {
    let offset = side === 'top' ? this.geometry.headerHeight || 0 : 0;
    if (side === 'bottom') {
      if ((this.geometry.footerRatio ?? 0) <= 0.5) offset += this.geometry.visibleFooterHeight || 0;
      offset += this.geometry.scrollbarHeight || 0;
    }
    let width = Math.min(this.geometry.tableWidth ?? Infinity, this.geometry.overflowWidth ?? Infinity);
    return htmlSafe(`${side}:${offset}px;${Number.isFinite(width) ? `width:${width}px` : ''}`);
  }

  get leftStyle() { return this.horizontalStyle('left'); }
  get rightStyle() { return this.horizontalStyle('right'); }
  get topStyle() { return this.verticalStyle('top'); }
  get bottomStyle() { return this.verticalStyle('bottom'); }

  <template>
    {{#if this.showLeft}}<div data-test-ember-table-scroll-indicator="left" class="scroll-indicator scroll-indicator__left" style={{this.leftStyle}}></div>{{/if}}
    {{#if this.showRight}}<div data-test-ember-table-scroll-indicator="right" class="scroll-indicator scroll-indicator__right" style={{this.rightStyle}}></div>{{/if}}
    {{#if this.showTop}}<div data-test-ember-table-scroll-indicator="top" class="scroll-indicator scroll-indicator__top" style={{this.topStyle}}></div>{{/if}}
    {{#if this.showBottom}}<div data-test-ember-table-scroll-indicator="bottom" class="scroll-indicator scroll-indicator__bottom" style={{this.bottomStyle}}></div>{{/if}}
  </template>
}
