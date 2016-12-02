'use babel';

import * as path from 'path';

const validPath = path.join(__dirname, 'fixtures', 'valid.rb');
const cawsvpath = path.join(__dirname, 'fixtures', 'cawsv.rb');
const emptyPath = path.join(__dirname, 'fixtures', 'empty.rb');

const lint = require('../lib/main.js').provideLinter().lint;

describe('The haml-lint provider for Linter', () => {
  beforeEach(() => {
    atom.workspace.destroyActivePaneItem();
    if (!atom.packages.isPackageDisabled('language-ruby')) {
      atom.packages.disablePackage('language-ruby');
    }
    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('linter-haml'),
        atom.packages.activatePackage('language-haml'),
      ]).then(() =>
        atom.workspace.open(validPath),
      ),
    );
  });

  describe('checks a file with issues and', () => {
    let editor = null;
    beforeEach(() => {
      waitsForPromise(() =>
        atom.workspace.open(cawsvpath).then((openEditor) => { editor = openEditor; }),
      );
    });

    it('finds at least one message', () => {
      waitsForPromise(() =>
        lint(editor).then(messages =>
          expect(messages.length).toBeGreaterThan(0),
        ),
      );
    });

    it('verifies the first message', () => {
      waitsForPromise(() => {
        const messageText = '<a href="' +
          'https://github.com/brigade/haml-lint/blob/master/lib/haml_lint/linter/README.md' +
          '#classattributewithstaticvalue">ClassAttributeWithStaticValue</a>: ' +
          'Avoid defining `class` in attributes hash for static class names';
        return lint(editor).then((messages) => {
          expect(messages[0].type).toBe('Warning');
          expect(messages[0].text).not.toBeDefined();
          expect(messages[0].html).toBe(messageText);
          expect(messages[0].filePath).toBe(cawsvpath);
          expect(messages[0].range).toEqual([[0, 0], [0, 23]]);
        });
      });
    });
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() =>
      atom.workspace.open(validPath).then(editor =>
        lint(editor).then(messages =>
          expect(messages.length).toBe(0),
        ),
      ),
    );
  });

  it('finds nothing wrong with an empty file', () => {
    waitsForPromise(() =>
      atom.workspace.open(emptyPath).then(editor =>
        lint(editor).then(messages =>
          expect(messages.length).toBe(0),
        ),
      ),
    );
  });
});
