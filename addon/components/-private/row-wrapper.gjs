import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import EmberObject, { get, set } from '@ember/object';
import { objectAt } from '../../-private/utils/array';

// Cell and row APIs are stable objects whose getters derive everything from
// the owning `RowWrapper`'s arguments. Rows recycled by the virtual collection
// therefore update through autotracking alone, and `cellValue` tracks the
// row's value at the column's `valuePath` via `get`.
class CellApi {
  constructor(row, index) {
    this._row = row;
    this._index = index;
  }

  get rowValue() {
    return this._row.args.rowValue;
  }

  get rowMeta() {
    return this._row.rowMeta;
  }

  get rowsCount() {
    return this._row.args.rowsCount;
  }

  get columnValue() {
    return objectAt(this._row.args.columns, this._index);
  }

  get columnMeta() {
    return this._row.args.columnMetaCache.get(this.columnValue);
  }

  get rowSelectionMode() {
    return this._row.rowSelectionMode;
  }

  get checkboxSelectionMode() {
    return this._row.args.canSelect ? this._row.args.checkboxSelectionMode : 'none';
  }

  get valuePath() {
    let columnValue = this.columnValue;
    return columnValue ? get(columnValue, 'valuePath') : undefined;
  }

  get cellValue() {
    let { rowValue, valuePath } = this;
    return rowValue != null && valuePath ? get(rowValue, valuePath) : undefined;
  }

  set cellValue(value) {
    let { rowValue, valuePath } = this;
    if (rowValue != null && valuePath) {
      set(rowValue, valuePath, value);
    }
  }

  get cellMeta() {
    let cache = this.rowMeta._cellMetaCache;
    let columnValue = this.columnValue;
    let meta = cache.get(columnValue);
    if (!meta) {
      meta = EmberObject.create();
      cache.set(columnValue, meta);
    }
    return meta;
  }
}

class RowApi {
  constructor(row) {
    this._row = row;
  }

  get rowValue() {
    return this._row.args.rowValue;
  }

  get rowMeta() {
    return this._row.rowMeta;
  }

  get cells() {
    return this._row.cells;
  }

  get rowSelectionMode() {
    return this._row.rowSelectionMode;
  }

  get rowToggleMode() {
    return this._row.args.rowToggleMode;
  }

  get rowsCount() {
    return this._row.args.rowsCount;
  }
}

export default class RowWrapper extends Component {
  api = new RowApi(this);
  _cells = [];

  get rowMeta() {
    return this.args.rowMetaCache.get(this.args.rowValue);
  }

  get rowSelectionMode() {
    return this.args.canSelect ? this.args.rowSelectionMode : 'none';
  }

  @cached
  get cells() {
    let count = get(this.args.columns, 'length');
    while (this._cells.length < count) {
      this._cells.push(new CellApi(this, this._cells.length));
    }
    this._cells.length = count;
    return this._cells.slice();
  }

  <template>{{yield this.api}}</template>
}
