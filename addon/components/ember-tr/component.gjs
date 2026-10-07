import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { closest } from '../../-private/utils/element';
import { SELECT_MODE } from '../../-private/collapse-tree';
import EmberTh from '../ember-th/component';
import EmberTd from '../ember-td/component';

export default class EmberTr extends Component {
  get customClass() { return this.args.class ?? ''; }
  get api() { return this.args.api; }
  get rowValue() { return this.api?.rowValue; }
  get rowMeta() { return this.api?.rowMeta; }
  get cells() { return this.api?.cells ?? []; }
  get rowSelectionMode() { return this.api?.rowSelectionMode; }
  get rowToggleMode() { return this.api?.rowToggleMode; }
  get isHeader() { return this.api?.isHeader; }
  get isSelected() { return this.rowMeta?.isSelected; }
  get isGroupSelected() { return this.rowMeta?.isGroupSelected; }
  get isEven() { return (this.rowMeta?.index ?? 0) % 2 === 0; }

  get isSelectable() {
    return [SELECT_MODE.MULTIPLE, SELECT_MODE.SINGLE].includes(this.rowSelectionMode);
  }

  @action
  click(event) {
    let inputParent = closest(event.target, 'input, button, label, a, select');

    if (!inputParent && this.rowMeta && this.rowSelectionMode === SELECT_MODE.MULTIPLE) {
      this.rowMeta.select({
        toggle: event.ctrlKey || event.metaKey || this.rowToggleMode,
        range: event.shiftKey,
      });
    } else if (!inputParent && this.rowMeta && this.rowSelectionMode === SELECT_MODE.SINGLE) {
      this.rowMeta.select({ single: true });
    }

    this.sendEventAction(this.args.onClick, event);
  }

  @action
  doubleClick(event) {
    this.sendEventAction(this.args.onDoubleClick, event);
  }

  sendEventAction(callback, event) {
    callback?.({ event, rowValue: this.rowValue, rowMeta: this.rowMeta });
  }

  <template>
    <tr
      ...attributes
      class="et-tr {{this.customClass}} {{if this.isEven 'is-even' 'is-odd'}} {{if this.isGroupSelected 'is-group-selected'}} {{if this.isSelectable 'is-selectable'}} {{if this.isSelected 'is-selected'}}"
      {{on "click" this.click}}
      {{on "dblclick" this.doubleClick}}
    >
      {{#each this.cells as |api|}}
        {{#if (has-block)}}
          {{#if this.isHeader}}
            {{yield (hash
              columnValue=api.columnValue
              columnMeta=api.columnMeta
              sorts=api.sorts
              sendUpdateSort=api.sendUpdateSort
              rowMeta=api.rowMeta
              rowsCount=api.rowsCount
              cell=(component EmberTh api=api)
            )}}
          {{else}}
            {{yield (hash
              api=api
              cellValue=api.cellValue
              cellMeta=api.cellMeta
              columnValue=api.columnValue
              columnMeta=api.columnMeta
              rowValue=api.rowValue
              rowMeta=api.rowMeta
              rowsCount=api.rowsCount
              cell=(component EmberTd api=api)
            )}}
          {{/if}}
        {{else if this.isHeader}}
          <EmberTh @api={{api}} />
        {{else}}
          <EmberTd @api={{api}} />
        {{/if}}
      {{/each}}
    </tr>
  </template>
}
