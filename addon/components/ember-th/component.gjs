/* global Hammer */
import BaseTableCell from '../-private/base-table-cell';
import { action, get } from '@ember/object';
import { next } from '@ember/runloop';
import { on } from '@ember/modifier';
import { didInsert, didUpdate, willDestroy } from '@ember/render-modifiers';
import { closest } from '../../-private/utils/element';
import SortIndicator from './sort-indicator/component';
import ResizeHandle from './resize-handle/component';

const INACTIVE = 0;
const RESIZING = 1;
const REORDERING = 2;

export default class EmberTh extends BaseTableCell {
  _columnState = INACTIVE;
  _hammer = null;

  get api() { return this.args.api; }
  get columnValue() { return this.api?.columnValue; }
  get columnMeta() { return this.api?.columnMeta; }
  get rowMeta() { return this.api?.rowMeta; }
  get sorts() { return this.api?.sorts ?? []; }
  get isSortable() { return this.columnMeta?.isSortable; }
  get isResizable() { return this.columnMeta?.isResizable; }
  get isReorderable() { return this.columnMeta?.isReorderable; }
  get columnSpan() { return this.columnMeta?.columnSpan; }
  get rowSpan() { return this.columnMeta?.rowSpan; }

  @action
  setup(element) {
    this.columnMeta.registerElement(element);
    let hammer = new Hammer(element);
    hammer.add(new Hammer.Press({ time: 0 }));
    hammer.on('press', this.pressHandler);
    hammer.on('panstart', this.panStartHandler);
    hammer.on('panmove', this.panMoveHandler);
    hammer.on('panend', this.panEndHandler);
    this._hammer = hammer;
    this.updateStyles(element);
  }

  @action
  teardown() {
    if (!this._hammer) return;
    for (let event of ['press', 'panstart', 'panmove', 'panend']) this._hammer.off(event);
    this._hammer.destroy();
  }

  @action sendDropdownAction(...args) { this.args.onDropdownAction?.(...args); }

  @action
  click(event) {
    let input = closest(event.target, 'button:not(.et-sort-toggle), input, label, a, select');
    if (this._columnState === INACTIVE && !input && this.isSortable) {
      this.updateSort({ toggle: event.ctrlKey || event.metaKey });
    }
  }

  @action contextMenu(event) { this.args.onContextMenu?.(event); }

  @action
  keyUp(event) {
    let input = closest(event.target, 'button:not(.et-sort-toggle), input, label, a, select');
    if (this._columnState === INACTIVE && !input && event.key === 'Enter' && this.isSortable) {
      this.updateSort({ toggle: false });
    }
  }

  updateSort({ toggle }) {
    let valuePath = this.columnValue.valuePath;
    let existing = this.sorts.find(sort => get(sort, 'valuePath') === valuePath);
    let updated = toggle ? this.sorts.filter(sort => get(sort, 'valuePath') !== valuePath) : [];
    if (!existing) updated.push({ valuePath, isAscending: false });
    else if (existing.isAscending === false) updated.push({ valuePath, isAscending: true });
    this.api.sendUpdateSort(updated);
  }

  @action pressHandler(event) {
    let [{ clientX, target }] = event.pointers;
    this._originalClientX = clientX;
    this._originalTargetWasResize = target.classList.contains('et-header-resize-area');
  }

  @action panStartHandler(event) {
    let [{ clientX }] = event.pointers;
    if (this.isResizable && this._originalTargetWasResize) {
      this._columnState = RESIZING;
      this.columnMeta.startResize(this._originalClientX);
    } else if (this.isReorderable) {
      this._columnState = REORDERING;
      this.columnMeta.startReorder(clientX);
    }
  }

  @action panMoveHandler(event) {
    let [{ clientX }] = event.pointers;
    if (this._columnState === RESIZING) this.columnMeta.updateResize(clientX);
    else if (this._columnState === REORDERING) this.columnMeta.updateReorder(clientX);
  }

  @action panEndHandler() {
    if (this._columnState === RESIZING) this.columnMeta.endResize();
    else if (this._columnState === REORDERING) this.columnMeta.endReorder();
    next(() => (this._columnState = INACTIVE));
  }

  <template>
    <th
      ...attributes
      colspan={{this.columnSpan}}
      rowspan={{this.rowSpan}}
      class="{{this.cellClass}} {{if this.isSortable 'is-sortable'}} {{if this.isResizable 'is-resizable'}} {{if this.isReorderable 'is-reorderable'}}"
      data-test-ember-table-slack={{if this.isSlack true}}
      {{didInsert this.setup}}
      {{didUpdate this.updateStyles this.columnMeta?.width this.columnMeta?.offsetLeft this.columnMeta?.offsetRight}}
      {{willDestroy this.teardown}}
      {{on "click" this.click}}
      {{on "contextmenu" this.contextMenu}}
      {{on "keyup" this.keyUp}}
    >
      {{#if (has-block)}}
        {{yield this.columnValue this.columnMeta this.rowMeta}}
      {{else}}
        {{this.columnValue.name}}
        <SortIndicator @columnMeta={{this.columnMeta}} />
        <ResizeHandle @columnMeta={{this.columnMeta}} />
      {{/if}}
    </th>
  </template>
}
