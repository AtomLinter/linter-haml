# linter-haml

[![Build Status](https://travis-ci.org/AtomLinter/linter-haml.svg?branch=master)](https://travis-ci.org/AtomLinter/linter-haml)

This linter plugin for [Linter][] provides
an interface to [haml-lint][]. It will be
used with files that have the "HAML" syntax.

## Installation

### Dependencies

This plugin requires a separate package to be installed to run it and provide
an interface. If [Linter][] is not
installed already, it will be installed for you to provide this.

Linter-haml relies on the HAML-lint gem to perform linting. If you do not
currently have HAML-lint installed, follow the instructions [here][haml-lint].

As Atom doesn't include a HAML language by default, [language-haml][]
will be installed for you if it isn't already. You will likely want to disable
`language-ruby` as it will mark all files as Ruby before `language-haml`.

If you prefer an alternative to any of the above packages that are installed
for you, simply disable them.

### Plugin installation
```
$ apm install linter-haml
```

## Settings

`linter-haml` can be configured from Atom's Settings menu in the Packages
section. All available options are shown there.

## Contributing
If you would like to contribute enhancements or fixes, please do the following:

1.  Fork the plugin repository.
2.  Hack on a separate topic branch created from the latest `master`.
3.  Commit and push the topic branch.
4.  Make a pull request.
5.  welcome to the club

[linter]: https://atom.io/packages/linter
[haml-lint]: https://github.com/causes/haml-lint
[language-haml]: https://atom.io/packages/language-haml
