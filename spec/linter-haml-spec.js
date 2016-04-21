'use babel';

import * as path from 'path';

const validPath = path.join(__dirname, 'fixtures', 'valid.rb');
const cawsvpath = path.join(__dirname, 'fixtures', 'cawsv.rb');
const emptyPath = path.join(__dirname, 'fixtures', 'empty.rb');

const Linter = require(path.join('..', 'lib', 'linter'));

describe('The haml-lint provider for Linter', () => {
  const lint = new Linter().lint;

  beforeEach(() => {
    atom.workspace.destroyActivePaneItem();
    if (!atom.packages.isPackageDisabled('language-ruby')) {
      atom.packages.disablePackage('language-ruby');
    }
    waitsForPromise(() =>
      atom.packages.activatePackage('linter-haml').then(() =>
        atom.packages.activatePackage('language-haml').then(() =>
          atom.workspace.open(validPath)
        )
      )
    );
  });

  describe('checks a file with issues and', () => {
    let editor = null;
    beforeEach(() => {
      waitsForPromise(() =>
        atom.workspace.open(cawsvpath).then(openEditor => { editor = openEditor; })
      );
    });

    it('finds at least one message', () => {
      waitsForPromise(() =>
        lint(editor).then(messages =>
          expect(messages.length).toBeGreaterThan(0)
        )
      );
    });

    it('verifies the first message', () => {
      waitsForPromise(() => {
        const messageText = 'ClassAttributeWithStaticValue: Avoid defining ' +
          '`class` in attributes hash for static class names';
        return lint(editor).then(messages => {
          expect(messages[0].type).toEqual('Warning');
          expect(messages[0].text).toEqual(messageText);
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
          expect(messages.length).toEqual(0)
        )
      )
    );
  });

  it('finds nothing wrong with an empty file', () => {
    waitsForPromise(() =>
      atom.workspace.open(emptyPath).then(editor =>
        lint(editor).then(messages =>
          expect(messages.length).toEqual(0)
        )
      )
    );
  });
});
