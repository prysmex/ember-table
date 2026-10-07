import EmberTableRow from 'ember-table/components/ember-tr/component';

export default class CustomRow extends EmberTableRow {
  get customClass() { return 'custom-row'; }
}
