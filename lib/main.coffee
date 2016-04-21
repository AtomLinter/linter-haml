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

    globalHamlLintYmlFile:
      default: ''
      description: 'Full path to a global Haml lint file, if no other is found'
      type: 'string'

  deactivate: =>
    @linter.subscriptions.dispose()

  provideLinter: =>
    @linter
