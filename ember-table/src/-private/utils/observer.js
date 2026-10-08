import {
  addObserver as emberAddObserver,
  removeObserver as emberRemoveObserver,
} from '@ember/object/observers';

// The classic models rely on asynchronous observers, which fire on tag
// invalidation before each render rather than synchronously on every `set`.
export function addObserver(obj, path, method) {
  // eslint-disable-next-line ember/no-observers
  return emberAddObserver(obj, path, null, method, false);
}

export function removeObserver(obj, path, method) {
  return emberRemoveObserver(obj, path, null, method, false);
}
