import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import EmberObject, { get, setProperties, computed, defineProperty } from '@ember/object';
import { alias } from '@ember/object/computed';
import { registerDestructor } from '@ember/destroyable';
import { notifyPropertyChange } from '../../-private/utils/ember';
import { objectAt } from '../../-private/utils/array';
import { addObserver, observer, removeObserver } from '../../-private/utils/observer';

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
  @tracked renderRevision = 0;

  constructor(owner, args) {
    super(owner, args);
    this._invalidate = () => this.renderRevision++;
    registerDestructor(this, () => this._cells.forEach(cell => cell.destroy()));
    registerDestructor(this, () => {
      if (this._observedRowMeta) {
        for (let key of ['isSelected', 'isGroupSelected', 'isCollapsed']) {
          removeObserver(this._observedRowMeta, key, this._invalidate);
        }
      }
    });
  }

  get rowMeta() {
    let rowMeta = this.args.rowMetaCache.get(this.args.rowValue);
    if (rowMeta !== this._observedRowMeta) {
      if (this._observedRowMeta) {
        for (let key of ['isSelected', 'isGroupSelected', 'isCollapsed']) {
          removeObserver(this._observedRowMeta, key, this._invalidate);
        }
      }
      this._observedRowMeta = rowMeta;
      if (rowMeta) {
        for (let key of ['isSelected', 'isGroupSelected', 'isCollapsed']) {
          addObserver(rowMeta, key, this._invalidate);
        }
      }
    }
    return rowMeta;
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
    this.renderRevision;
    return {
      rowValue: this.args.rowValue,
      rowMeta: this.rowMeta,
      cells: this.cells,
      rowSelectionMode: this.args.canSelect ? this.args.rowSelectionMode : 'none',
      rowToggleMode: this.args.rowToggleMode,
      rowsCount: this.args.rowsCount,
      selection: this.args.selection,
      selectionMatchFunction: this.args.selectionMatchFunction,
    };
  }

  <template>{{yield this.api}}</template>
}
