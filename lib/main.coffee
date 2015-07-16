{BufferedProcess, CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
fs = require 'fs'
fse = require 'fs-extra'
path = require 'path'
os = require 'os'
temp = require 'temp'
XRegExp = require('xregexp').XRegExp

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-haml.hamlLintExecutablePath', (executablePath) =>
      @executablePath = executablePath

  config:
    hamlLintExecutablePath:
      default: 'haml-lint'
      type: 'string'
      description: 'Path to haml-lint executable'

  copyHamlLintYml: (filePath, tempDir) ->
    new Promise (resolve, reject) =>
      @findFile filePath, '.haml-lint.yml'
      .then (hamlLintYmlPath) ->
        return resolve() unless hamlLintYmlPath

        fse.copy hamlLintYmlPath, path.join(tempDir, '.haml-lint.yml'), (error) ->
          return reject Error(error) if error
          resolve()

  copyRubocopYml: (filePath, tempDir) ->
    new Promise (resolve, reject) =>
      @findFile filePath, '.rubocop.yml'
      .then (rubocopYmlPath) ->
        console.log 'rubocopYmlPath', rubocopYmlPath
        return resolve() unless rubocopYmlPath

        fse.copy rubocopYmlPath, path.join(tempDir, '.rubocop.yml'), (error) ->
          return reject Error(error) if error
          resolve()

  deactivate: ->
    @subscriptions.dispose()

  findFile: (filePath, fileName) ->
    new Promise (resolve, reject) ->
      foundPath = helpers.findFile filePath, fileName
      unless foundPath
        homeDir = process.env.HOME || process.env.USERPROFILE
        homePath = path.join homeDir, fileName
        fs.exists homePath, (exists) ->
          foundPath = homePath if exists
      resolve foundPath

  lintFile: (tempFile, filePath) ->
    new Promise (resolve, reject) =>
      output = []
      process = new BufferedProcess
        command: @executablePath
        args: [tempFile]
        options:
          cwd: path.dirname tempFile
        stdout: (data) ->
          output.push data
        exit: (code) ->
          XRegExp ?= require('xregexp').XRegExp
          regex = XRegExp '.+?:(?<line>\\d+) ' +
            '\\[((?<warning>W)|(?<error>E))\\] ' +
            '(?<message>.+)'
          messages = []
          XRegExp.forEach output, regex, (match, i) ->
            messages.push
              type: if match.warning? then 'warning' else 'error'
              text: match.message
              filePath: filePath
              range: [
                [match.line - 1, 0],
                [match.line - 1, 999]
              ]
          resolve messages

  makeTempDir: ->
    new Promise (resolve, reject) ->
      temp.mkdir 'AtomLinter', (error, directory) ->
        return reject Error(error) if error
        resolve directory

  # TODO: write a class and return a new instance of it here
  provideLinter: ->
    provider =
      grammarScopes: ['text.haml']

      lint: (textEditor) =>
        return new Promise (resolve, reject) =>
          # write contents to tempfile in tempdir
          # find/copy .rubocop.yml to tempdir
          # find/copy .haml-lint.yml to tempdir
          # copy editor content to tempdir
          # lint tempfile with cwd at tempdir
          # remove tempdir

          filePath = textEditor.getPath()
          results = []
          tempDir = undefined
          @makeTempDir().then (dir) =>
            tempDir = dir
            @copyRubocopYml filePath, tempDir
          .then =>
            @copyHamlLintYml filePath, tempDir
          .then =>
            @writeTempFile tempDir, textEditor
          .then (tempFile) =>
            @lintFile tempFile, filePath
          .then (messages) ->
            results = messages
          .then =>
            @removeTempDir tempDir
          .then ->
            resolve results
          .catch (error) ->
            console.error 'linter-haml error', error
            resolve results

      lintOnFly: true

      scope: 'file'

  removeTempDir: (tempDir) ->
    new Promise (resolve, reject) ->
      fse.remove tempDir, (error) ->
        return reject Error(error) if error
        resolve()

  writeTempFile: (tempDir, textEditor) ->
    new Promise (resolve, reject) ->
      tempFile = path.join tempDir, path.basename(textEditor.getPath())
      fse.writeFile tempFile, textEditor.getText(), (error) ->
        return reject Error(error) if error
        resolve tempFile
