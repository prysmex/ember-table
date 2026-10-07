import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class BaseTableCell extends Component {
  get columnMeta() { return this.args.api?.columnMeta ?? this.args.columnMeta; }
  get columnValue() { return this.args.api?.columnValue ?? this.args.columnValue; }
  get isFirstColumn() { return this.columnMeta?.index === 0; }
  get isLastColumn() { return this.columnMeta?.isLastRendered; }
  get isFixedLeft() { return this.columnMeta?.isFixed === 'left'; }
  get isFixedRight() { return this.columnMeta?.isFixed === 'right'; }
  get isSlack() { return this.columnMeta?.isSlack; }

  get cellClass() {
    let classes = [];
    if (this.isFirstColumn) classes.push('is-first-column');
    if (this.isLastColumn) classes.push('is-last-column');
    if (this.isFixedLeft) classes.push('is-fixed-left');
    if (this.isFixedRight) classes.push('is-fixed-right');
    if (this.isSlack) classes.push('is-slack');
    let alignment = this.columnValue?.textAlign;
    if (['left', 'center', 'right'].includes(alignment)) {
      classes.push(`ember-table__text-align-${alignment}`);
    }
    return classes.join(' ');
  }

  @action
  updateStyles(element) {
    if (typeof FastBoot !== 'undefined' || !this.columnMeta) return;
    let width = `${this.columnMeta.width}px`;
    element.style.width = width;
    element.style.minWidth = width;
    element.style.maxWidth = width;
    element.style.left = this.isFixedLeft ? `${Math.round(this.columnMeta.offsetLeft)}px` : '';
    element.style.right = this.isFixedRight ? `${Math.round(this.columnMeta.offsetRight)}px` : '';
    if (this.isSlack) {
      element.style.paddingLeft = '0';
      element.style.paddingRight = '0';
      element.style.display = width === '0px' ? 'none' : 'table-cell';
    }
  }
}
