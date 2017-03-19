'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';

import * as helpers from 'atom-linter';
import escapeHtml from 'escape-html';
import { dirname } from 'path';

// Some internal variables
let executablePath;
let globalHamlLintYmlFile;

const regex = /.+?:(\d+) \[(W|E)] (\w+): (.+)/g;
const urlBase = 'https://github.com/brigade/haml-lint/blob/master/lib/haml_lint/linter/README.md';

export default {
  activate() {
    require('atom-package-deps').install('linter-haml');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-haml.executablePath', (value) => {
        executablePath = value;
      }),
    );
    this.subscriptions.add(
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
      lintOnFly: false,
      lint: async (textEditor) => {
        const filePath = textEditor.getPath();
        const text = textEditor.getText();

        const options = {
          cwd: dirname(filePath),
          ignoreExitCode: true,
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

        const output = await helpers.exec(executablePath, parameters, options);

        if (textEditor.getText() !== text) {
          // eslint-disable-next-line no-console
          console.warn('linter-haml:: The file was modified since the ' +
            'request was sent to check it. Since any results would no longer ' +
            'be valid, they are not being updated. Please save the file ' +
            'again to update the results.');
          return null;
        }

        const messages = [];
        let match = regex.exec(output);
        while (match !== null) {
          const type = match[2] === 'W' ? 'Warning' : 'Error';
          const line = Number.parseInt(match[1], 10) - 1;
          const ruleName = escapeHtml(match[3]);
          const message = escapeHtml(match[4]);
          messages.push({
            type,
            filePath,
            range: helpers.generateRange(textEditor, line),
            html: `<a href="${urlBase}#${ruleName.toLowerCase()}">${ruleName}</a>: ${message}`,
          });

          match = regex.exec(output);
        }
        return messages;
      },
    };
  },
};
