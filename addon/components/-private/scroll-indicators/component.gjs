/* global ResizeSensor */
import Component from '@glimmer/component';
import { action, get } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { registerDestructor } from '@ember/destroyable';
import { didInsert, didUpdate } from '@ember/render-modifiers';

export default class ScrollIndicators extends Component {
  @tracked geometry = {};
  _isListening = false;

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => this.removeListeners());
  }

  get api() { return this.args.api?.api ?? this.args.api; }
  get columnTree() { return this.api?.columnTree; }
  get enabledIndicators() {
    switch (this.api?.scrollIndicators) {
      case true: case 'all': return ['left', 'right', 'top', 'bottom'];
      case 'horizontal': return ['left', 'right'];
      case 'vertical': return ['top', 'bottom'];
      default: return [];
    }
  }
  get showLeft() { return this.enabledIndicators.includes('left') && this.geometry.scrollLeft > 0; }
  get showRight() { return this.enabledIndicators.includes('right') && this.geometry.scrollRight > 0; }
  get showTop() { return this.enabledIndicators.includes('top') && this.geometry.scrollTop > 0; }
  get showBottom() { return this.enabledIndicators.includes('bottom') && this.geometry.scrollBottom > 0; }

  horizontalStyle(side) {
    let fixed = get(this.columnTree, `${side}FixedNodes`) ?? [];
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

  @action setup() { this.updateListeners(); }
  @action update() { this.updateListeners(); }

  updateListeners() {
    let enabled = this.enabledIndicators.length > 0;
    if (enabled && !this._isListening) this.addListeners();
    else if (!enabled && this._isListening) this.removeListeners();
  }

  addListeners() {
    this._scrollElement = document.getElementById(this.api.tableId);
    if (!this._scrollElement) return;
    this._isListening = true;
    this._tableElement = this._scrollElement.querySelector('table');
    this._headerElement = this._tableElement.querySelector('thead');
    this._scrollElement.addEventListener('scroll', this.updateIndicators);
    this._tableResizeSensor = new ResizeSensor(this._tableElement, this.updateIndicators);
    this.addFooterListeners();
    this.updateIndicators();
  }

  removeListeners() {
    if (!this._isListening) return;
    this._isListening = false;
    this._scrollElement?.removeEventListener('scroll', this.updateIndicators);
    this._tableResizeSensor?.detach();
    this.removeFooterListeners();
  }

  addFooterListeners() {
    let footer = this._tableElement?.querySelector('tfoot');
    if (!footer) return;
    this._footerResizeSensor ??= new ResizeSensor(footer, this.updateIndicators);
    if (!this._footerMutationObserver) {
      this._footerMutationObserver = new MutationObserver(this.updateIndicators);
      this._footerMutationObserver.observe(footer, {
        subtree: true, attributes: true, attributesFilter: ['style'], childList: true,
      });
    }
  }

  removeFooterListeners() {
    this._footerResizeSensor?.detach();
    this._footerResizeSensor = null;
    this._footerMutationObserver?.disconnect();
    this._footerMutationObserver = null;
  }

  @action
  updateIndicators() {
    let element = this._scrollElement;
    let table = this._tableElement;
    if (!element || !table) return;
    let scrollLeft = element.scrollLeft;
    let scrollTop = element.scrollTop;
    let visibleFooterHeight = 0;
    let footerCell = table.querySelector('tfoot td');
    if (footerCell) {
      this.addFooterListeners();
      let rect = element.getBoundingClientRect();
      let scale = element.offsetHeight / rect.height;
      visibleFooterHeight = Math.max(0, Math.min(
        element.clientHeight - scale * (footerCell.getBoundingClientRect().y - rect.y),
        element.clientHeight
      ));
    } else this.removeFooterListeners();

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
      headerHeight: this._headerElement?.offsetHeight,
      visibleFooterHeight,
      footerRatio: element.offsetHeight ? visibleFooterHeight / element.offsetHeight : undefined,
    };
  }

  <template>
    <span hidden {{didInsert this.setup}} {{didUpdate this.update this.api.scrollIndicators}}></span>
    {{#if this.showLeft}}<div data-test-ember-table-scroll-indicator="left" class="scroll-indicator scroll-indicator__left" style={{this.leftStyle}}></div>{{/if}}
    {{#if this.showRight}}<div data-test-ember-table-scroll-indicator="right" class="scroll-indicator scroll-indicator__right" style={{this.rightStyle}}></div>{{/if}}
    {{#if this.showTop}}<div data-test-ember-table-scroll-indicator="top" class="scroll-indicator scroll-indicator__top" style={{this.topStyle}}></div>{{/if}}
    {{#if this.showBottom}}<div data-test-ember-table-scroll-indicator="bottom" class="scroll-indicator scroll-indicator__bottom" style={{this.bottomStyle}}></div>{{/if}}
  </template>
}
