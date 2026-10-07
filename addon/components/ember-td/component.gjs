import BaseTableCell from '../-private/base-table-cell';
import { action, set } from '@ember/object';
import { on } from '@ember/modifier';
import { didInsert, didUpdate } from '@ember/render-modifiers';
import { SELECT_MODE } from '../../-private/collapse-tree';
import EmberTableSimpleCheckbox from '../ember-table-simple-checkbox';

let setupSimpleCheckboxForTest = false;
export function setSimpleCheckboxForTest(value) {
  setupSimpleCheckboxForTest = value;
}

export default class EmberTd extends BaseTableCell {
  get api() { return this.args.api?.api ?? this.args.api; }
  get cellValue() { return this.api?.cellValue; }
  set cellValue(value) {
    let rowValue = this.rowValue;
    let valuePath = this.columnValue?.valuePath;
    if (rowValue && valuePath) {
      set(rowValue, valuePath, value);
    }
    return value;
  }
  get cellMeta() { return this.api?.cellMeta; }
  get columnValue() { return this.api?.columnValue; }
  get columnMeta() { return this.api?.columnMeta; }
  get rowValue() { return this.api?.rowValue; }
  get rowMeta() { return this.api?.rowMeta; }
  get rowsCount() { return this.api?.rowsCount; }
  get rowSelectionMode() { return this.api?.rowSelectionMode; }
  get checkboxSelectionMode() { return this.api?.checkboxSelectionMode; }
  get canCollapse() { return this.rowMeta?.canCollapse; }
  get depthClass() { return `depth-${this.rowMeta?.depth}`; }
  get isTesting() { return setupSimpleCheckboxForTest; }

  get shouldShowCheckbox() {
    return [SELECT_MODE.MULTIPLE, SELECT_MODE.SINGLE].includes(this.checkboxSelectionMode);
  }

  get canSelect() {
    return this.shouldShowCheckbox ||
      [SELECT_MODE.MULTIPLE, SELECT_MODE.SINGLE].includes(this.rowSelectionMode);
  }

  @action
  onSelectionToggled(event) {
    let mode = this.checkboxSelectionMode || this.rowSelectionMode;
    if (this.rowMeta && mode === SELECT_MODE.MULTIPLE) {
      this.rowMeta.select({ toggle: true, range: event.shiftKey });
    } else if (this.rowMeta && mode === SELECT_MODE.SINGLE) {
      this.rowMeta.select();
    }
    this.sendFullAction(this.args.onSelect);
  }

  @action
  onCollapseToggled() {
    this.rowMeta.toggleCollapse();
    this.sendFullAction(this.args.onCollapse);
  }

  @action click(event) { this.sendFullAction(this.args.onClick, { event }); }
  @action doubleClick(event) { this.sendFullAction(this.args.onDoubleClick, { event }); }

  sendFullAction(callback, values = {}) {
    callback?.(Object.assign(values, {
      cellValue: this.cellValue,
      cellMeta: this.cellMeta,
      columnValue: this.columnValue,
      columnMeta: this.columnMeta,
      rowValue: this.rowValue,
      rowMeta: this.rowMeta,
    }));
  }

  <template>
    <td
      ...attributes
      class={{this.cellClass}}
      data-test-ember-table-slack={{if this.isSlack true}}
      {{didInsert this.updateStyles}}
      {{didUpdate this.updateStyles this.columnMeta?.width this.columnMeta?.offsetLeft this.columnMeta?.offsetRight}}
      {{on "click" this.click}}
      {{on "dblclick" this.doubleClick}}
    >
      {{#if this.isFirstColumn}}
        <div class="et-cell-container">
          {{#if this.canSelect}}
            <span class="et-toggle-select {{unless this.shouldShowCheckbox 'et-speech-only'}}" data-test-select-row-container>
              <EmberTableSimpleCheckbox
                @checked={{this.rowMeta.isGroupSelected}}
                @onClick={{this.onSelectionToggled}}
                @ariaLabel="Select row"
                @dataTestSelectRow={{this.isTesting}}
              />
              <span></span>
            </span>
          {{/if}}
          {{#if this.canCollapse}}
            <span class="et-toggle-collapse et-depth-indent {{this.depthClass}}">
              <EmberTableSimpleCheckbox
                @checked={{this.rowMeta.isCollapsed}}
                @onChange={{this.onCollapseToggled}}
                @ariaLabel="Collapse row"
                @dataTestCollapseRow={{this.isTesting}}
              />
              <span></span>
            </span>
          {{else}}
            <div class="et-depth-indent et-depth-placeholder {{this.depthClass}}"></div>
          {{/if}}
          <div class="et-cell-content">
            {{#if (has-block)}}
              {{yield this.cellValue this.columnValue this.rowValue this.cellMeta this.columnMeta this.rowMeta this.rowsCount}}
            {{else}}
              {{this.cellValue}}
            {{/if}}
          </div>
        </div>
      {{else if (has-block)}}
        {{yield this.cellValue this.columnValue this.rowValue this.cellMeta this.columnMeta this.rowMeta this.rowsCount}}
      {{else}}
        {{this.cellValue}}
      {{/if}}
    </td>
  </template>
}
