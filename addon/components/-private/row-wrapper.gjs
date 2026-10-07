import Component from '@glimmer/component';
import EmberObject, { get, setProperties, computed, defineProperty } from '@ember/object';
import { alias } from '@ember/object/computed';
import { registerDestructor } from '@ember/destroyable';
import { notifyPropertyChange } from '../../-private/utils/ember';
import { objectAt } from '../../-private/utils/array';
import { observer } from '../../-private/utils/observer';

const CellWrapper = EmberObject.extend({
  columnValueValuePathDidChange: observer('columnValue.valuePath', function() {
    let path = get(this, 'columnValue.valuePath');
    defineProperty(this, 'cellValue', path ? alias(`rowValue.${path}`) : null);
    notifyPropertyChange(this, 'cellValue');
  }),

  cellMeta: computed('rowMeta', 'columnValue', function() {
    let rowMeta = get(this, 'rowMeta');
    let columnValue = get(this, 'columnValue');
    if (!rowMeta._cellMetaCache.has(columnValue)) {
      rowMeta._cellMetaCache.set(columnValue, EmberObject.create());
    }
    return rowMeta._cellMetaCache.get(columnValue);
  }),
});

export default class RowWrapper extends Component {
  _cells = [];

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => this._cells.forEach(cell => cell.destroy()));
  }

  get rowMeta() {
    return this.args.rowMetaCache.get(this.args.rowValue);
  }

  get cells() {
    let columns = this.args.columns;
    let count = get(columns, 'length');

    while (this._cells.length < count) this._cells.push(CellWrapper.create());
    while (this._cells.length > count) this._cells.pop().destroy();

    this._cells.forEach((cell, index) => {
      let columnValue = objectAt(columns, index);
      setProperties(cell, {
        checkboxSelectionMode: this.args.canSelect ? this.args.checkboxSelectionMode : 'none',
        columnMeta: this.args.columnMetaCache.get(columnValue),
        columnValue,
        rowMeta: this.rowMeta,
        rowSelectionMode: this.args.canSelect ? this.args.rowSelectionMode : 'none',
        rowValue: this.args.rowValue,
        rowsCount: this.args.rowsCount,
      });
    });
    return this._cells;
  }

  get api() {
    return {
      rowValue: this.args.rowValue,
      rowMeta: this.rowMeta,
      cells: this.cells,
      rowSelectionMode: this.args.canSelect ? this.args.rowSelectionMode : 'none',
      rowToggleMode: this.args.rowToggleMode,
      rowsCount: this.args.rowsCount,
    };
  }

  <template>{{yield this.api}}</template>
}
