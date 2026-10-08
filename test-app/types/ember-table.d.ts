// ember-table's `./test-support` export has no `types` condition, so point it
// at the declarations the `./*` export maps. Remove once the export has types.
declare module 'ember-table/test-support' {
  export * from 'ember-table/test-support/index';
}
