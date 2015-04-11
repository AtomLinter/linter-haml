linter-haml
=========================

This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides an interface to [haml-lint](https://github.com/causes/haml-lint). It will be used with files that have the "HAML" syntax.

## Installation

### Dependencies

This plugin requires the Linter package to be installed. If Linter is not installed, please follow the instructions [here](https://github.com/AtomLinter/Linter).

Linter-haml relies on the HAML-lint gem to perform linting. If you do not currently have HAML-lint installed, follow the instructions [here](https://github.com/causes/haml-lint).

You may also need to install the [language-haml](https://github.com/cannikin/language-haml) plugin.

### Plugin installation
```
$ apm install linter-haml
```

## Settings
You can configure linter-haml by editing ~/.atom/config.cson (choose Open Your Config in Atom menu):
```
'linter-haml-lint':
  'hamlLintExecutablePath': null #haml-lint path. run 'which haml-lint' to find the path
```

## Contributing
If you would like to contribute enhancements or fixes, please do the following:

1. Fork the plugin repository.
1. Hack on a separate topic branch created from the latest `master`.
1. Commit and push the topic branch.
1. Make a pull request.
1. welcome to the club
