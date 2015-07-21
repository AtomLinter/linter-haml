Linter = require './linter'

module.exports =
  activate: =>
    @linter = new Linter

  config:
    copyRubocopYml:
      default: true
      description: 'Copy .rubocop.yml to temporary directory while linting'
      type: 'boolean'

    hamlLintExecutablePath:
      default: 'haml-lint'
      description: 'Path to haml-lint executable'
      type: 'string'

  deactivate: =>
    @linter.subscriptions.dispose()

  provideLinter: =>
    @linter
