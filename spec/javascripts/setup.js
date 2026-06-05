const fs = require('fs');
const path = require('path');
const jquery = require('jquery');

// Make jQuery available globally
global.$ = jquery;
global.jQuery = jquery;

// Load jQuery UI dist
const jqueryUiPath = require.resolve('jquery-ui-dist/jquery-ui.js');
const jqueryUiJs = fs.readFileSync(jqueryUiPath, 'utf8');
eval(jqueryUiJs);

// Load moj namespace
const mojJs = fs.readFileSync(path.join(__dirname, '../../vendor/assets/javascripts/moj.js'), 'utf8');
eval(mojJs);

// Load GOVUK namespace from gem
const govukToolkitPath = path.join(process.env.GOVUK_TOOLKIT_PATH || '', 'app/assets/javascripts/govuk');

if (fs.existsSync(govukToolkitPath)) {
  fs.readdirSync(govukToolkitPath)
    .filter(f => f.endsWith('.js'))
    .forEach(f => {
      try {
        const govukJs = fs.readFileSync(path.join(govukToolkitPath, f), 'utf8');
        eval(govukJs);
      } catch (e) {
        // skip files that fail to load in test environment
      }
    });
}

// Load application.js to get $.urlParam and other helpers
const appJs = fs.readFileSync(path.join(__dirname, '../../app/assets/javascripts/application.js'), 'utf8');
eval(appJs);

// Load all modules
const modulesDir = path.join(__dirname, '../../app/assets/javascripts/modules');
fs.readdirSync(modulesDir)
  .filter(f => f.endsWith('.js'))
  .forEach(f => {
    const moduleJs = fs.readFileSync(path.join(modulesDir, f), 'utf8');
    eval(moduleJs);
  });

global.moj = moj;

// Expose Jasmine-compatible spyOn globally (stub by default, like Jasmine)
global.spyOn = (obj, methodName) => jest.spyOn(obj, methodName).mockImplementation(() => {});
