import TablePage from './pages/ember-table';
import { setSetupRowCountForTest } from '../components/ember-tbody/component.gts';
import { setupTHeadForTest } from '../components/ember-thead/component.gts';
import { setSimpleCheckboxForTest } from '../components/ember-td/component.gts';

function setupForTest() {
  setSetupRowCountForTest(true);
  setupTHeadForTest(true);
  setSimpleCheckboxForTest(true);
}

export { TablePage, setupForTest };
