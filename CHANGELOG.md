# Changes

## 1.1.0

*   [#17](https://github.com/AtomLinter/linter-haml/pull/17),
    [#20](https://github.com/AtomLinter/linter-haml/pull/20),
    [#22](https://github.com/AtomLinter/linter-haml/pull/22): Dependency updates

*   [#21](https://github.com/AtomLinter/linter-haml/pull/21): A few fixes,
    including:

    *   Use `rangeFromLineNumber` to generate the ranges for line highlighting

    *   Use `helpers.exec()` to run the program instead of using Atom's
        BufferedProcess (directly)

    *   Specify a name for the linter so its messages can be identified

    *   Automatically install [`linter`](https://github.com/atom-community/linter)

## 1.0.0

*   [#11](https://github.com/AtomLinter/linter-haml/pull/11): Rewrite for new
    Linter API

    *   **Breaking change**: Configuration is no longer namespaced under
    `linter-haml-lint`, but under `linter-haml`.  As such, previously configured
    `hamlLintExecutablePath` will not work.  You can either change the namespace
    in your `config.cson` or change the package settings with Atom's GUI to set
    an appropriate value.

## 0.4.0

*   [#6](https://github.com/AtomLinter/linter-haml/pull/6): Use
    `activationCommands` instead of deprecated `activationEvents` in
    `package.json`

## 0.3.0

*   [#3](https://github.com/AtomLinter/linter-haml/pull/3): Update readme to
    better explain dependencies

*   [#4](https://github.com/AtomLinter/linter-haml/pull/4): Dispose config
    listeners

## 0.1.1

*   [#1](https://github.com/AtomLinter/linter-haml/issues/1): Support for
    setting path to `haml-lint` executable

## 0.1.0

*   Initial implementation
