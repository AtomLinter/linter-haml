'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';

import * as helpers from 'atom-linter';
import escapeHtml from 'escape-html';
import { dirname } from 'path';

// Some internal variables
let executablePath;
let globalHamlLintYmlFile;

const warning = 'warning';
const regex = /.+?:(\d+) \[(W|E)] (\w+): (.+)/g;
const urlBase = 'https://github.com/brigade/haml-lint/blob/master/lib/haml_lint/linter/README.md';

const showErrorNotification = (text = 'HAML-Lint: Unexpected error', description) => {
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
          showErrorNotification(e.message);
          return null;
        }

        const messages = [];

        if (output.exitCode !== 0) {
          if (output.stderr.toLowerCase().startsWith(warning)) {
            messages.push({
              severity: warning,
              excerpt: `haml-lint: ${output.stderr}`,
              location: {
                file: filePath,
                // first line of the file
                position: [[0, 0], [0, Infinity]],
              },
            });
          } else {
            showErrorNotification(output.stderr);
            return null;
          }
        }

        if (textEditor.getText() !== text) {
          // eslint-disable-next-line no-console
          console.warn('linter-haml:: The file was modified since the ' +
            'request was sent to check it. Since any results would no longer ' +
            'be valid, they are not being updated. Please save the file ' +
            'again to update the results.');
          return null;
        }

        let match = regex.exec(output.stdout);
        while (match !== null) {
          const severity = match[2] === 'W' ? warning : 'error';
          const line = Number.parseInt(match[1], 10) - 1;
          const ruleName = escapeHtml(match[3]);
          const excerpt = match[4];
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
