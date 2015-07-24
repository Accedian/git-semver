# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).
This file uses change log convention from [Keep a CHANGELOG](http://keepachangelog.com).

## [Unreleased][unreleased]

## [2.0.0] - 2015-07-24
### Added
- New plugin architecture. Changelog validation is now disabled by default.

## [1.1.2] - 2015-07-22
### Fixed
- Moved disown to git-semver.sh
- Pull down tags on update check
- Optimise get version in setting
- Check if commit is on a branch befire outputting help on amending commits

## [1.1.1] - 2015-07-22
### Fixed
- Update now runs installer
- Workaround when writing stub to avoid permission errors

## [1.1.0] - 2015-07-07
### Added
- Update checks
- Ability to disable changelog checks
- Purge option to uninstaller to remove configuration files

### Fixed
- Installer symlink on MinGW

## [1.0.2] - 2015-07-06
### Fixed
- Bug in reading previous version from [CHANGELOG.md]
- Installer to use ~/bin first if possible

## [1.0.1] - 2015-06-08
### Added
- [CONTRIBUTING.md]
- Help for recommiting after change

### Fixed
- [README.md]
- Bugs in reading git origin
- Show all errors in one go
- More compatible with Windows (and possibly OSX)

## 1.0.0 - 2015-06-08
### Added
- Initial version
- Readme file with documentation [README.md]
- Licence file [LICENCE.md]
- Installer and uninstaller

[CHANGELOG.md]: CHANGELOG.md
[CONTRIBUTING.md]: CONTRIBUTING.md
[LICENCE.md]: LICENCE.md
[README.md]: README.md

[unreleased]: https://github.com/markchalloner/git-semver/compare/1.1.2...HEAD
[2.0.0]: https://github.com/markchalloner/git-semver/compare/1.1.2...2.0.0
[1.1.2]: https://github.com/markchalloner/git-semver/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/markchalloner/git-semver/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/markchalloner/git-semver/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/markchalloner/git-semver/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/markchalloner/git-semver/compare/1.0.0...1.0.1
