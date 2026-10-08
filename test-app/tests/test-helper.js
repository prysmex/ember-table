import Application from 'test-app/app';
import config from 'test-app/config/environment';
import * as QUnit from 'qunit';
import { setApplication } from '@ember/test-helpers';
import { setup } from 'qunit-dom';
import { start as qunitStart, setupEmberOnerrorValidation } from 'ember-qunit';
import { setupForTest as setupEmberTableForTest } from 'ember-table/test-support';
import {
  setup as setupWarnHandlers,
  teardown as teardownWarnHandlers,
} from './helpers/warn-handlers';

export function start() {
  setApplication(Application.create(config.APP));

  setup(QUnit.assert);
  setupEmberOnerrorValidation();

  QUnit.testStart(() => {
    setupEmberTableForTest();
    setupWarnHandlers();
  });

  QUnit.testDone(() => {
    teardownWarnHandlers();
  });

  qunitStart();
}
