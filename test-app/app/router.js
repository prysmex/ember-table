import EmberRouter from '@embroider/router';
import { addDocfyRoutes } from '@docfy/ember';
import config from 'test-app/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  addDocfyRoutes(this);

  this.route('scenarios', function () {
    this.route('simple');
    this.route('performance');
    this.route('blank');
  });

  this.route('not-found', { path: '/*path' });
});
