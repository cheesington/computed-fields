Package.describe({
  name: 'maximum:computed-fields',
  summary: 'Meteor package for automatic computation of field values in a collection',
  version: '0.2.1',
  git: 'https://github.com/maximummeteor/computed-fields.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');
  api.use([
    'coffeescript',
    'underscore',
    'check',
    'lai:collection-extensions@0.2.1_1',
    'matb33:collection-hooks@0.8.1',
  ], 'server');
  api.use([
    'coffeescript',
    'underscore',
    'check',
  ], 'client');

  api.addFiles([
    'lib/computed-fields.coffee',
    'lib/collection2.coffee',
  ], 'server');
  api.addFiles([
    'lib/collection2.coffee',
  ], 'client');
});


Package.onTest(function (api) {
  api.use('tinytest');
  api.use('coffeescript');
  api.use('mongo');
  api.use('aldeed:collection2@2.0.0');
  api.use('maximum:computed-fields');

  api.addFiles([
    'tests/collection2.coffee',
  ], 'client');
  api.addFiles([
    'tests/basic.coffee',
    'tests/collection2.coffee',
  ], 'server');
});
