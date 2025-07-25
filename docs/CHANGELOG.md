# Changelog

All notable changes to MagSafe Guard will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This changelog is automatically maintained by release-please -->
<!-- Do not manually edit below this line -->

## [1.2.0](https://github.com/lekman/magsafe-buskill/compare/v1.1.0...v1.2.0) (2025-07-25)


### Features

* add documentation structure and deployment workflow for GitHub Pages ([c9a5c9f](https://github.com/lekman/magsafe-buskill/commit/c9a5c9fc0ae5b7f70d6e6f8de48982d3e16622d6))
* implement power monitoring service and demo UI ([0e8192c](https://github.com/lekman/magsafe-buskill/commit/0e8192cd9c5609e82d4a35f9bbac1fac24b944dd))


### Documentation

* Add troubleshooting guide, security implementation guide, and integrate Semgrep and Snyk for enhanced security in MagSafe Guard ([afa2d54](https://github.com/lekman/magsafe-buskill/commit/afa2d54c7a2c440bb727171c61b0448ae93ed0b9))
* improve formatting in various documentation files for consistency ([1716873](https://github.com/lekman/magsafe-buskill/commit/1716873bea340a6c4fb8f2acbfb7807974e0615a))
* reorganize documentation structure and improve test coverage ([5442a2d](https://github.com/lekman/magsafe-buskill/commit/5442a2d464440dc3a9dcbf9c17491e73e150318f))
* restore and update Quality Assurance Dashboard with comprehensive analysis tools and project metrics ([9fabe47](https://github.com/lekman/magsafe-buskill/commit/9fabe4785c89e0f22004c0d6a1f5b5866014276c))
* update README with new quick links and improve development instructions ([90a2d44](https://github.com/lekman/magsafe-buskill/commit/90a2d44c6a5a8bd1f63dbafe9941c015aca88d9b))
* update Snyk and SonarCloud links for improved accuracy and navigation ([2db46f0](https://github.com/lekman/magsafe-buskill/commit/2db46f01184bad5cda272104bf33eb39ba159ab4))


### Code Refactoring

* add job names for clarity in release workflow ([c5697e1](https://github.com/lekman/magsafe-buskill/commit/c5697e1d3ec165a9789e34c02f52a9fb27c0e065))
* enhance auto-approve action with required labels and path filters ([dfc795b](https://github.com/lekman/magsafe-buskill/commit/dfc795b930bc378c315d5b9dc2041a0c217828a5))
* enhance CodeQL build process for Swift projects ([72b3772](https://github.com/lekman/magsafe-buskill/commit/72b3772b0cc24eaf2c53e23a3e72520f89002250))
* remove unused GitHub Actions workflow and clean up documentation files ([99a03c0](https://github.com/lekman/magsafe-buskill/commit/99a03c0a211708d2da180e589cb45a441a33e225))
* simplify PowerMonitorDemoView by extracting view components for better readability ([7cb1ce5](https://github.com/lekman/magsafe-buskill/commit/7cb1ce58765d016c7e2469f1fc43669d4ca0f21d))
* streamline CODEOWNERS and QA.md for clarity and organization ([8e028ba](https://github.com/lekman/magsafe-buskill/commit/8e028baa0cb5d54bb739c6d64cf38f560a15761c))
* update auto-approve action to use secret token and add required labels and path filters ([5011361](https://github.com/lekman/magsafe-buskill/commit/50113616148b328c3d2bb28d3dd50059f4e1c3b4))
* update CODEOWNERS and release workflow for better file ownership and permissions ([cf0b85d](https://github.com/lekman/magsafe-buskill/commit/cf0b85d3c99db1b331894bb28edc9fc771d299d4))
* update pull request trigger and condition for auto-approve job ([e839a52](https://github.com/lekman/magsafe-buskill/commit/e839a52d489561f83d2309bdd8134bcd070a3bba))


### Tests

* remove example test and update PowerMonitorServiceTests for async operations ([0ae2332](https://github.com/lekman/magsafe-buskill/commit/0ae233239482bb65d07851dd500ebedb89b5dc3a))

## [1.1.0](https://github.com/lekman/magsafe-buskill/compare/v1.0.0...v1.1.0) (2025-07-24)


### Features

* add cancel redundant workflows action to multiple workflows ([97103a2](https://github.com/lekman/magsafe-buskill/commit/97103a29e2d42d592c7a5b7a9261dff0e874d464))
* add CI/CD workflows documentation to project ([c23eb93](https://github.com/lekman/magsafe-buskill/commit/c23eb932dd4c1f10a435f19f3e80f095e925c9ad))
* implement commit message enforcement and block prohibited words ([4a69143](https://github.com/lekman/magsafe-buskill/commit/4a69143971a2eeb2b6b178a62ad1342ca15cac9a))
* Initial implementation of MagSafe Guard application ([9a180e4](https://github.com/lekman/magsafe-buskill/commit/9a180e4bded4edd71b60c54e53d364606698c1d1))
* Initial implementation of MagSafe Guard application ([2210239](https://github.com/lekman/magsafe-buskill/commit/2210239b807a25d8b3a7e628c51b034d524cd8c0))


### Bug Fixes

* update minimum macOS deployment target to 13.0 ([7f55208](https://github.com/lekman/magsafe-buskill/commit/7f55208dc19a1428970320d0e776b3371ffdca2e))
* update variable references in GitHub Actions summary for clarity ([c0df60b](https://github.com/lekman/magsafe-buskill/commit/c0df60ba18bfdee9265f0fc8857169dc7af64bab))

## 1.0.0 (2025-07-24)

### Features

- add CODEOWNERS and security workflows for enhanced code review and security auditing ([8d4d5be](https://github.com/lekman/magsafe-buskill/commit/8d4d5bece1b4a48b172f4d466e515165f252aae6))
- add CONTRIBUTORS guide to outline contribution process and community standards ([abb5ae9](https://github.com/lekman/magsafe-buskill/commit/abb5ae96d4007ac66cf6fa1d7112897be2dc343e))
- add initial configuration files and README for MagSafe BusKill project ([57b0850](https://github.com/lekman/magsafe-buskill/commit/57b0850d22fde2d2efa74bdd8703a9a8d6f36fe5))
- add pull request template for consistent PR submissions ([3321135](https://github.com/lekman/magsafe-buskill/commit/33211351acee4e7c9d5d05b57270df9a66e1901f))
- add quality assurance dashboard with quick links and project status badges ([52dd87b](https://github.com/lekman/magsafe-buskill/commit/52dd87b849518848d8c12f5e823124be8de9e912))
- add release-please configuration and workflows for automated releases ([d1bf68f](https://github.com/lekman/magsafe-buskill/commit/d1bf68fef01023549b1e6095c3d8dd8a9d916a57))
- enhance Codecov integration by generating lcov coverage report and updating workflow documentation ([7977c1d](https://github.com/lekman/magsafe-buskill/commit/7977c1dcc29c12bdc00e541393d6773c4f206e83))
- enhance documentation and setup for Figma integration, security hooks, and development environment ([365be78](https://github.com/lekman/magsafe-buskill/commit/365be78a3849a3864dc522d4a7601a23ccf0b313))
- enhance secret detection in security checks by refining patterns and filtering results ([59ba9fe](https://github.com/lekman/magsafe-buskill/commit/59ba9fee8fc98aa144fe0ad36f53548ec1a1beba))
- enhance security scanning with Snyk integration and Semgrep results upload ([8e07f10](https://github.com/lekman/magsafe-buskill/commit/8e07f10f6453291bdca93d78ef2cecb36fe13075))
- enhance security workflows with Semgrep integration and basic security scanning ([f40b803](https://github.com/lekman/magsafe-buskill/commit/f40b80399c27462499473d9bba164a978979881d))
- implement CodeQL analysis and add initial project structure with tests ([b246ec2](https://github.com/lekman/magsafe-buskill/commit/b246ec2f2fc56a060f1df92ac694f46b443eff84))
- Initial Prototype ([cfaa882](https://github.com/lekman/magsafe-buskill/commit/cfaa882fd19785efa88a49b69b8a1d4ff75bcf2e))
- integrate Codecov for enhanced test coverage reporting and add coverage badge to README ([4596961](https://github.com/lekman/magsafe-buskill/commit/45969616e5a395d01af209b7994e460140c882d1))
- prototype to implement authentication flow and configuration for MagSafe Guard ([210c8ea](https://github.com/lekman/magsafe-buskill/commit/210c8ea1463c42f77741316ac401cb585e003377))
- rename project from MagSafe BusKill to MagSafe Guard and update related documentation ([ef9b0a8](https://github.com/lekman/magsafe-buskill/commit/ef9b0a8cf581d42c7b8ab46e1d51ce04837ce742))
- update allowed licenses in security workflow to include MPL-2.0 and AGPL-3.0 ([d3bcba3](https://github.com/lekman/magsafe-buskill/commit/d3bcba307b0640c9645a290bab64ee7aca841880))

### Bug Fixes

- update copyright year in LICENSE file to 2025 ([399e0ad](https://github.com/lekman/magsafe-buskill/commit/399e0ad2eb1c60fa72330cbfac89ba01ce2ed5a4))

### Documentation

- clarify Code Climate and SonarCloud status for OSS in QA dashboard ([600d343](https://github.com/lekman/magsafe-buskill/commit/600d343f6e61bfe4c539514553a03824ae8919be))
- improve formatting and clarity in Codecov integration guide for Swift ([3f4b528](https://github.com/lekman/magsafe-buskill/commit/3f4b528c2cdcae9be8bd818f7669a68bd78c1ef2))
- update Snyk integration guide to note commented workflow in security.yml ([0c443b7](https://github.com/lekman/magsafe-buskill/commit/0c443b7a6813295bea7429cb4c97d82fc70dca64))
