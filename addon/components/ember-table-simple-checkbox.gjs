import Component from '@glimmer/component';
import { action } from '@ember/object';
import { didInsert, didUpdate } from '@ember/render-modifiers';
import { on } from '@ember/modifier';

export default class EmberTableSimpleCheckbox extends Component {
  get type() {
    return this.args.type ?? 'checkbox';
  }

  @action
  captureElement(element) {
    element.indeterminate = Boolean(this.args.indeterminate);
  }

  @action
  updateIndeterminate(element, [indeterminate]) {
    element.indeterminate = Boolean(indeterminate);
  }

  @action
  click(event) {
    this.args.onClick?.(event);
  }

  @action
  change(event) {
    let element = event.currentTarget;
    let checked = element.checked;
    let indeterminate = element.indeterminate;

    element.checked = Boolean(this.args.checked);
    element.indeterminate = Boolean(this.args.indeterminate);

    this.args.onChange?.(checked, { value: this.args.value, indeterminate }, event);
  }

  <template>
    <input
      type={{this.type}}
      aria-label={{@ariaLabel}}
      checked={{@checked}}
      disabled={{@disabled}}
      value={{@value}}
      data-test-select-row={{@dataTestSelectRow}}
      data-test-collapse-row={{@dataTestCollapseRow}}
      {{didInsert this.captureElement}}
      {{didUpdate this.updateIndeterminate @indeterminate}}
      {{on "click" this.click}}
      {{on "change" this.change}}
    />
  </template>
}
