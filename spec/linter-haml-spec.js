'use babel';

// eslint-disable-next-line no-unused-vars
import { it, fit, wait, beforeEach, afterEach } from 'jasmine-fix';
import * as path from 'path';

const validPath = path.join(__dirname, 'fixtures', 'valid.rb');
const cawsvpath = path.join(__dirname, 'fixtures', 'cawsv.rb');
const emptyPath = path.join(__dirname, 'fixtures', 'empty.rb');

const { lint } = require('../lib/main.js').provideLinter();

describe('The haml-lint provider for Linter', () => {
  beforeEach(async () => {
    atom.workspace.destroyActivePaneItem();
    if (!atom.packages.isPackageDisabled('language-ruby')) {
      atom.packages.disablePackage('language-ruby');
    }
    await atom.packages.activatePackage('linter-haml');
    await atom.packages.activatePackage('language-haml');
  });

  it('checks a file with issues', async () => {
    const editor = await atom.workspace.open(cawsvpath);
    const messages = await lint(editor);
    const url = 'https://github.com/brigade/haml-lint/blob/master/lib/haml_lint/linter/README.md' +
      '#classattributewithstaticvalue';
    const excerpt = 'ClassAttributeWithStaticValue: Avoid defining `class` in attributes hash for static class names';

    expect(messages.length).toBe(1);
    expect(messages[0].severity).toBe('warning');
    expect(messages[0].excerpt).toBe(excerpt);
    expect(messages[0].description).not.toBeDefined();
    expect(messages[0].url).toBe(url);
    expect(messages[0].location.file).toBe(cawsvpath);
    expect(messages[0].location.position).toEqual([[0, 0], [0, 23]]);
  });

  it('finds nothing wrong with a valid file', async () => {
    const editor = await atom.workspace.open(validPath);
    const messages = await lint(editor);

    expect(messages.length).toBe(0);
  });

  it('finds nothing wrong with an empty file', async () => {
    const editor = await atom.workspace.open(emptyPath);
    const messages = await lint(editor);

    expect(messages.length).toBe(0);
  });
});
