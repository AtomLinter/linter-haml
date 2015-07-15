{BufferedProcess, CompositeDisposable} = require 'atom'
fs = require 'fs'
fse = require 'fs-extra'
path = require 'path'
os = require 'os'
temp = require 'temp'
uuid = require 'node-uuid'
XRegExp = require('xregexp').XRegExp

console.log 'os', os
console.log 'tmpdir', os.tmpdir()

module.exports =
  config:
    hamlLintExecutablePath:
      default: 'haml-lint'
      type: 'string'
      description: 'Path to haml-lint executable'
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-haml-lint.hamlLintExecutablePath', (executablePath) =>
      @executablePath = executablePath
  deactivate: ->
    @subscriptions.dispose()
  provideLinter: ->
    console.log 'qwer'
    provider =
      grammarScopes: ['text.haml']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        console.log 'zxcv'
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
            console.log 'dir', dir
            tempDir = dir
            @copyRubocopYml filePath, tempDir
          .then =>
            @copyHamlLintYml filePath, tempDir
          .then =>
            @writeTempFile tempDir, textEditor
          .then (tempFile) =>
            console.log 'tempFile', tempFile
            @lintFile tempFile, filePath
          .then (messages) =>
            results = messages
          .then =>
            @removeTempDir tempDir
            resolve results

          # debugger
          # tempDir = path.join(os.tmpdir(), 'AtomLinter', 'linter-haml', uuid.v1())
          # console.log 'tempDir', tempDir
          #
          # promise = new Promise (resolve, reject) =>
          #   fse.mkdirp (error) =>
          #     if error then reject Error(error) else resolve
          #
          # promise.then ->
          #   console.log 'created tempDir'




  copyHamlLintYml: (filePath, tempDir) ->
    console.log 'copyHamlLintYml'
    new Promise (resolve, reject) =>
      console.log 'looking for haml-lint.yml'
      hamlLintYmlPath = @findFile(filePath, '.haml-lint.yml', false, null, [process.env.HOME || process.env.USERPROFILE])
      console.log 'hamlLintYmlPath', hamlLintYmlPath
      return resolve() unless hamlLintYmlPath

      fse.copy hamlLintYmlPath, path.join(tempDir, '.haml-lint.yml'), (error) ->
        console.log 'copying haml-lint.yml'
        reject Error(error) if error
        resolve()

  copyRubocopYml: (filePath, tempDir) ->
    console.log 'copyRubocopYml'
    new Promise (resolve, reject) =>
      console.log 'looking for rubocop.yml'
      rubocopYmlPath = @findFile(filePath, '.rubocop.yml', false, null, [process.env.HOME || process.env.USERPROFILE])
      console.log 'rubocopYmlPath', rubocopYmlPath
      return resolve() unless rubocopYmlPath

      fse.copy rubocopYmlPath, path.join(tempDir, '.rubocop.yml'), (error) ->
        console.log 'copying rubocop.yml'
        reject Error(error) if error
        resolve()

  findFile: (startDir, name, parent = false, limit = null, aux_dirs = []) ->
    # Find the given file by searching up the file hierarchy from startDir.
    #
    # If the file is found and parent is false, returns the path to the file.
    # If parent is true the path to the file's parent directory is returned.
    #
    # If limit is null or <= 0, the search will continue up to the root directory.
    # Otherwise a maximum of limit directories will be checked.
    #
    # If aux_dirs is not empty and the file hierarchy search failed,
    # those directories are also checked.

    climb = startDir.split(path.sep)
    for item in climb
      dir = climb.join(path.sep) + path.sep

      nameType = {}.toString.call(name)
      if nameType is '[object Array]'
        for n in name
          target = path.join(dir, n)

          if fs.existsSync(target)
            if parent
              return dir
            return target

      if nameType is '[object String]'
        target = path.join(dir, name)

        if fs.existsSync(target)
          if parent
            return dir
          return target

      climb.splice(-1,1)

  lintFile: (tempFile, filePath) ->
    new Promise (resolve, reject) =>
      output = []
      console.log '@executablePath', @executablePath
      process = new BufferedProcess
        command: @executablePath || 'haml-lint'
        args: [tempFile]
        options:
          cwd: path.dirname tempFile
        stderr: (data) ->
          console.log 'stderr', data
        stdout: (data) ->
          console.log 'stdout', data
          output.push data
        exit: (code) ->
          console.log 'code', code
          # return resolve [] unless code is 0
          XRegExp ?= require('xregexp').XRegExp
          regex = XRegExp '.+?:(?<line>\\d+) ' +
            '\\[((?<warning>W)|(?<error>E))\\] ' +
            '(?<message>.+)'
          console.log 'regex', regex
          messages = []
          XRegExp.forEach output, regex, (match, i) ->
            console.log 'match', match
            messages.push
              type: if match.warning? then 'warning' else 'error'
              text: match.message
              filePath: filePath
              range: [
                [match.line - 1, 0],
                [match.line - 1, 999]
              ]
          console.log messages, 'messages'
          resolve messages

  makeTempDir: ->
    new Promise (resolve, reject) ->
      temp.mkdir 'AtomLinter', (error, directory) ->
        reject Error(error) if error
        resolve directory

  removeTempDir: (tempDir) ->
    new Promise (resolve, reject) ->
      fse.remove tempDir, (error) ->
        reject Error(error) if error
        resolve()

  writeTempFile: (tempDir, textEditor) ->
    new Promise (resolve, reject) ->
      tempFile = path.join tempDir, path.basename(textEditor.getPath())
      fse.writeFile tempFile, textEditor.getText(), (error) ->
        reject Error(error) if error
        resolve tempFile
