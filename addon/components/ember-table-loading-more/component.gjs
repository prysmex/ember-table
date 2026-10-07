/* global ResizeSensor */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { registerDestructor } from '@ember/destroyable';
import { didInsert, didUpdate } from '@ember/render-modifiers';

export default class EmberTableLoadingMore extends Component {
  @tracked translateX = 0;
  element = null;

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => this.removeListeners());
  }

  get api() { return this.args.api?.api ?? this.args.api; }
  get scrollElement() { return this.api?.columnTree?.container; }
  get canLoadMore() { return this.args.canLoadMore ?? true; }
  get isLoading() { return this.args.isLoading ?? false; }
  get center() { return this.args.center ?? true; }

  get style() {
    let values = [
      `display:${this.canLoadMore ? '' : 'none'}`,
      `visibility:${this.isLoading ? '' : 'hidden'}`,
      `transform:${this.translateX ? `translateX(${this.translateX}px)` : ''}`,
    ];
    return htmlSafe(values.join(';'));
  }

  @action
  setup(element) {
    this.element = element;
    this.updateListeners();
    this.updateTransform();
  }

  @action
  update(element) {
    this.element = element;
    this.updateListeners();
    this.updateTransform();
  }

  updateListeners() {
    this.removeListeners();
    if (!this.center || !this.scrollElement) return;
    this.scrollElement.addEventListener('scroll', this.updateTransform);
    this._resizeSensor = new ResizeSensor(this.scrollElement, this.updateTransform);
  }

  removeListeners() {
    this.scrollElement?.removeEventListener('scroll', this.updateTransform);
    this._resizeSensor?.detach();
    this._resizeSensor = null;
  }

  @action
  updateTransform() {
    if (!this.scrollElement || !this.element) return;
    this.translateX = this.center
      ? Math.round(this.scrollElement.scrollLeft +
          (this.scrollElement.clientWidth - this.element.clientWidth) / 2)
      : 0;
  }

  <template>
    <div
      ...attributes
      class="ember-table-loading-more"
      data-test-ember-table-loading-more
      style={{this.style}}
      {{didInsert this.setup}}
      {{didUpdate this.update @center @canLoadMore @isLoading}}
    >
      {{yield}}
    </div>
  </template>
}
