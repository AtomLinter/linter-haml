{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
fs = require 'fs'
fse = require 'fs-extra'
path = require 'path'
temp = require 'temp'
XRegExp = require('xregexp').XRegExp

class Linter
  name: 'haml_lint'
  grammarScopes: ['text.haml']
  scope: 'file'
  lintOnFly: true

  constructor: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-haml.copyRubocopYml', (copyRubocopYml) =>
      @copyRubocopYml = copyRubocopYml
    @subscriptions.add atom.config.observe 'linter-haml.hamlLintExecutablePath', (executablePath) =>
      @executablePath = executablePath

  copyFile: (sourcePath, destinationPath) ->
    new Promise (resolve, reject) ->
      fse.copy sourcePath, destinationPath, (error) ->
        return reject Error(error) if error
        resolve()

  exists: (filePath) ->
    new Promise (resolve, reject) ->
      fs.exists filePath, (exists) ->
        resolve exists

  findFile: (filePath, fileName) =>
    new Promise (resolve, reject) =>
      foundPath = helpers.find filePath, fileName
      return resolve foundPath if foundPath

      homeDir = process.env.HOME || process.env.USERPROFILE
      homePath = path.join homeDir, fileName
      @exists homePath
      .then (exists) ->
        resolve if exists then homePath else undefined

  findHamlLintYmlFile: (filePath) =>
    new Promise (resolve, reject) =>
      @findFile filePath, '.haml-lint.yml'
      .then (hamlLintYmlPath) ->
        resolve hamlLintYmlPath

  findRubocopYmlFile: (filePath) =>
    new Promise (resolve, reject) =>
      @findFile filePath, '.rubocop.yml'
      .then (rubocopYmlPath) ->
        resolve rubocopYmlPath

  lint: (textEditor) =>
    new Promise (resolve, reject) =>
      fileContent = textEditor.getText()
      filePath = textEditor.getPath()
      fileName = path.basename filePath

      results = []
      rubocopYmlPath = undefined
      tempDir = undefined
      tempFile = undefined

      @makeTempDir().then (dir) =>
        tempDir = dir
        @writeTempFile(tempDir, fileName, fileContent)
      .then (file) =>
        tempFile = file
        @findRubocopYmlFile(filePath) if @copyRubocopYml
      .then (rubocopYmlPath) =>
        if rubocopYmlPath
          @copyFile rubocopYmlPath, path.join(tempDir, '.rubocop.yml')
      .then =>
        @findHamlLintYmlFile filePath
      .then (hamlLintYmlPath) =>
        @lintFile textEditor, tempFile, hamlLintYmlPath
      .then (messages) ->
        results = messages
      .then =>
        @removeTempDir tempDir
      .then ->
        resolve results
      .catch (error) ->
        console.error 'linter-haml error', error
        resolve results

  lintFile: (textEditor, tempFile, hamlLintYmlPath) ->
    new Promise (resolve, reject) =>
      filePath   = textEditor.getPath()
      textBuffer = textEditor.getBuffer()

      args = []
      if hamlLintYmlPath?
        args.push '--config'
        args.push hamlLintYmlPath
      args.push tempFile

      resolve helpers.exec(@executablePath, args).then (output) ->
        regex = XRegExp '.+?:(?<line>\\d+) ' +
        '\\[((?<warning>W)|(?<error>E))\\] ' +
        '(?<message>.+)'
        messages = []
        XRegExp.forEach output, regex, (match, i) ->
          messages.push
            type: if match.warning? then 'Warning' else 'Error'
            text: match.message
            filePath: filePath
            range: helpers.rangeFromLineNumber(textEditor, match.line - 1)
        return messages


  makeTempDir: ->
    new Promise (resolve, reject) ->
      temp.mkdir 'AtomLinter', (error, directory) ->
        return reject Error(error) if error
        resolve directory

  removeTempDir: (tempDir) ->
    new Promise (resolve, reject) ->
      fse.remove tempDir, (error) ->
        return reject Error(error) if error
        resolve()


  writeTempFile: (tempDir, fileName, fileContent) ->
    new Promise (resolve, reject) ->
      tempFile = path.join tempDir, fileName
      fse.writeFile tempFile, fileContent, (error) ->
        return reject Error(error) if error
        resolve tempFile

module.exports = Linter
