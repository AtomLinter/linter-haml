linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

class LinterHaml extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['text.haml']

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: 'haml-lint'

  linterName: 'haml-lint'

  regex:
    '.+?:(?<line>\\d+) ' +
    '\\[((?<warning>W)|(?<error>E))\\] ' +
    '(?<message>.+)'

  constructor: (editor) ->
    super(editor)

    @executablePathListener = atom.config.observe 'linter-haml-lint.hamlLintExecutablePath', =>
      @executablePath = atom.config.get 'linter-haml-lint.hamlLintExecutablePath'

  destroy: ->
    @executablePathListener.dispose()

module.exports = LinterHaml
