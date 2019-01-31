'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';

import * as helpers from 'atom-linter';
import escapeHtml from 'escape-html';
import { dirname } from 'path';

// Some internal variables
let executablePath;
let globalHamlLintYmlFile;
let suppressWarnings;

const regex = /.+?:(\d+) \[(W|E)] (\w+): (.+)/g;
const urlBase = 'https://github.com/brigade/haml-lint/blob/master/lib/haml_lint/linter/README.md';

const showErrorNotification = (text, description) => {
  atom.notifications.addError(text, { description });
};

export default {
  activate() {
    require('atom-package-deps').install('linter-haml');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-haml.executablePath', (value) => {
        executablePath = value;
      }),
      atom.config.observe('linter-haml.globalHamlLintYmlFile', (value) => {
        globalHamlLintYmlFile = value;
      }),
      atom.config.observe('linter-haml.suppressWarnings', (value) => {
        suppressWarnings = value;
      }),
    );
  },

  deactivate() {
    this.subscriptions.dispose();
  },

  provideLinter() {
    return {
      name: 'HAML-Lint',
      grammarScopes: ['text.haml'],
      scope: 'file',
      lintsOnChange: false,
      lint: async (textEditor) => {
        const filePath = textEditor.getPath();
        const text = textEditor.getText();

        const options = {
          cwd: dirname(filePath),
          stream: 'both',
          ignoreExitCode: true,
          uniqueKey: `linter-haml::${filePath}`,
        };
        const parameters = [];

        // Specify any configuration file
        const hamlLintYmlPath = await helpers.findAsync(options.cwd, '.haml-lint.yml');
        if (hamlLintYmlPath) {
          parameters.push('--config', hamlLintYmlPath);
        } else if (globalHamlLintYmlFile !== '') {
          parameters.push('--config', globalHamlLintYmlFile);
        }

        // Add the file to be linted
        parameters.push(filePath);

        let output;
        try {
          output = await helpers.exec(executablePath, parameters, options);
        } catch (e) {
          showErrorNotification('HAML-Lint: Unexpected error', e.message);
          return null;
        }

        if (output.exitCode !== 0) {
          if (!suppressWarnings && output.stderr.toLowerCase().startsWith('warning')) {
            atom.notifications.addWarning('HAML-Lint: Software error', {
              description: output.stderr,
            });
          }
        } else {
          showErrorNotification('HAML-Lint: Unexpected error', output.stderr);
        }

        if (textEditor.getText() !== text) {
          // eslint-disable-next-line no-console
          console.warn('linter-haml:: The file was modified since the ' +
            'request was sent to check it. Since any results would no longer ' +
            'be valid, they are not being updated. Please save the file ' +
            'again to update the results.');
          return null;
        }

        const messages = [];
        let match = regex.exec(output.stdout);
        while (match !== null) {
          const severity = match[2] === 'W' ? 'warning' : 'error';
          const line = Number.parseInt(match[1], 10) - 1;
          const ruleName = escapeHtml(match[3]);
          const excerpt = escapeHtml(match[4]);
          messages.push({
            url: `${urlBase}#${ruleName.toLowerCase()}`,
            severity,
            excerpt: `${ruleName}: ${excerpt}`,
            location: {
              file: filePath,
              position: helpers.generateRange(textEditor, line),
            },
          });

          match = regex.exec(output.stdout);
        }
        return messages;
      },
    };
  },
};
