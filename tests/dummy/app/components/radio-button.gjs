import Component from '@ember/component';

// Compatibility component for the legacy documentation examples. The former
// ember-radio-button dependency cannot build on current Ember CLI.
export default Component.extend({
  tagName: 'input',
  attributeBindings: ['name', 'type', 'value', 'checked'],
  type: 'radio',

  checked: false,

  change() {
    this.set('groupValue', this.value);
  },
});
