import { tracked } from '@glimmer/tracking';

/**
  The object shared between `<EmberTable>` and its sections. The header
  registers itself, and every header-owned value is derived from it, so
  readers are autotracked without the header having to push values in.
*/
export default class TableApi {
  @tracked head = null;

  columns = null;

  constructor(tableId) {
    this.tableId = tableId;
  }

  get columnTree() {
    return this.head?.columnTree;
  }

  get sorts() {
    return this.head?.sorts;
  }

  get sortFunction() {
    return this.head?.sortFunction;
  }

  get compareFunction() {
    return this.head?.compareFunction;
  }

  get sortEmptyLast() {
    return this.head?.sortEmptyLast;
  }

  get scrollIndicators() {
    return this.head?.scrollIndicators;
  }

  registerHead(head) {
    this.head = head;
  }

  unregisterHead(head) {
    if (this.head === head) {
      this.head = null;
    }
  }
}
