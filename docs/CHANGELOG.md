# Changelog

All notable changes to MagSafe Guard will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This changelog is automatically maintained by release-please -->
<!-- Do not manually edit below this line -->

## [1.5.0](https://github.com/lekman/magsafe-buskill/compare/v1.4.0...v1.5.0) (2025-07-26)


### Features

* Add manual acceptance test guide and update test coverage documentation ([5f6818a](https://github.com/lekman/magsafe-buskill/commit/5f6818a5539012e5fb36985257a737ee75778142))
* Add paths filter for release-please workflow triggers ([b489e7a](https://github.com/lekman/magsafe-buskill/commit/b489e7a07ef84b25bbea59549511f2ddb95dacf3))
* Add should-skip output for non-release-please branches in security and test workflows ([e003236](https://github.com/lekman/magsafe-buskill/commit/e003236256f25360566a2a40ce155fbd0904ff5e))
* Enhance security workflows with improved environment variable handling and commit checks ([cd782ac](https://github.com/lekman/magsafe-buskill/commit/cd782ac9c1c3286737ecd888901d17c0707c6503))
* Improve initialization comments in authentication and system actions classes ([dd06809](https://github.com/lekman/magsafe-buskill/commit/dd0680951f7d0c3bf01b9f7292de17de6b6a6e31))
* Update settings to exclude additional files and improve README task status ([4fe255e](https://github.com/lekman/magsafe-buskill/commit/4fe255ef14e3e67b171367e10fa15d1088a7b633))


### Code Refactoring

* Add slug to Codecov configuration for improved reporting ([2f1cb52](https://github.com/lekman/magsafe-buskill/commit/2f1cb52f7c9b6fd586c584d925d674224c42bdd5))
* Change require_ci_to_pass from 'yes' to 'true' in Codecov configuration ([d0a6e16](https://github.com/lekman/magsafe-buskill/commit/d0a6e166e9155a62f760c392643d68cdd165c01a))
* Correct file input key in Codecov action and remove unnecessary parameters ([52e3d7d](https://github.com/lekman/magsafe-buskill/commit/52e3d7db440e428adce9da06a0bd3b8babc49b98))
* Enhance CI/CD documentation and workflows for clarity and debugging ([4b22375](https://github.com/lekman/magsafe-buskill/commit/4b2237551ae6b57ee5ab479a74bf01627a3f277d))
* Ensure thread safety in recordAuthenticationAttempt method ([7034eaf](https://github.com/lekman/magsafe-buskill/commit/7034eafb0a85ff194d0d96d500a18d5674b3072a))
* Improve table formatting for third-party security tools in QA documentation ([c3aa1bb](https://github.com/lekman/magsafe-buskill/commit/c3aa1bb14149986c6046fae7f5b2d4db7327f40f))
* Improve variable naming for clarity in authentication and security services ([4feb62f](https://github.com/lekman/magsafe-buskill/commit/4feb62f03120ebb726737affc83bd336e6000aa9))
* Remove PowerMonitorCore.swift from coverage exclusions in Codecov and SonarCloud configurations ([000470b](https://github.com/lekman/magsafe-buskill/commit/000470b0602b692bf36369fd9f296bc30591a3f6))
* Rename default configuration property for clarity ([046774e](https://github.com/lekman/magsafe-buskill/commit/046774e99d4fc3319a3ab04096a241a45d5997f3))
* Simplify Codecov upload step by removing unnecessary parameters ([91a7b21](https://github.com/lekman/magsafe-buskill/commit/91a7b216b2ea2bceaef4a040edc097bc4abc8738))
* Simplify table formatting for analysis tools in QA documentation ([baa284a](https://github.com/lekman/magsafe-buskill/commit/baa284a29be4f26117bd9124d3d818268a7102e8))
* Standardize branch formatting and improve test workflow clarity ([cc291d7](https://github.com/lekman/magsafe-buskill/commit/cc291d78a338e106f9a5333eab836d01fe90d6b5))
* Update security workflow permissions and documentation for clarity ([c7ab96d](https://github.com/lekman/magsafe-buskill/commit/c7ab96dd24c5ce738eefcb5566c5200be03a93d0))
* Upgrade Codecov action to v5 for improved functionality ([60b0246](https://github.com/lekman/magsafe-buskill/commit/60b024604896674436f7b79960d8d9d932938642))

## [1.4.0](https://github.com/lekman/magsafe-buskill/compare/v1.3.0...v1.4.0) (2025-07-25)


### Features

* add skip condition for release-please branches in security and test workflows ([3ed0068](https://github.com/lekman/magsafe-buskill/commit/3ed0068e973e5cc411c4feac8adbe70f7c6cc7fa))

## [1.3.0](https://github.com/lekman/magsafe-buskill/compare/v1.2.0...v1.3.0) (2025-07-25)


### Features

* add LGPL-3.0 to allowed licenses in license compliance check ([eb533c8](https://github.com/lekman/magsafe-buskill/commit/eb533c8faf40faf5f13e91951cbfed2d6c6bc9a8))
* add Snyk policy file and justification for DeviceAuthenticationBypass warning; enhance AuthenticationService with detailed security measures ([e15bef0](https://github.com/lekman/magsafe-buskill/commit/e15bef0c930c94ef24ca83aded6ac0666dac49d2))
* add SonarCloud analysis workflow and coverage reporting for improved code quality ([11139b3](https://github.com/lekman/magsafe-buskill/commit/11139b32e13a9d1e7f870ca4329d61bbdbb703f9))
* enhance AuthenticationService with security hardening measures and comprehensive tests ([875d1df](https://github.com/lekman/magsafe-buskill/commit/875d1dfb85f9d692b38608c3f9a2b9ae51cde5dd))
* enhance CI testing for AuthenticationService by adding environment detection and adapting tests for CI execution ([78ab15e](https://github.com/lekman/magsafe-buskill/commit/78ab15ed8bd1e77378a2f7cc663cfc00522ac7aa))
* enhance SonarCloud coverage report generation and add exclusions for improved analysis ([ff23aee](https://github.com/lekman/magsafe-buskill/commit/ff23aeea4d2ac44130d8be17dccb68a5f95d7666))
* enhance test coverage tasks and add pre-PR checks for improved quality assurance ([f5cc076](https://github.com/lekman/magsafe-buskill/commit/f5cc076ff24bb31780aaf02d2999e4d9f78cab17))
* implement AuthenticationService with comprehensive error handling and caching mechanisms ([9f0af20](https://github.com/lekman/magsafe-buskill/commit/9f0af20b2fe9252bbb8b9574af0f0bbdde1077f6))
* implement caching strategy for Swift builds in CI workflows to optimize build times ([7c4f273](https://github.com/lekman/magsafe-buskill/commit/7c4f27390b633adda64f2ae080268ad472a7a852))
* implement comprehensive authentication service with biometric and password support ([dad7c21](https://github.com/lekman/magsafe-buskill/commit/dad7c2178739af6636fedbabbe86c6137dae4b6b))
* integrate Semgrep for enhanced security scanning with cloud rules support ([91c1d7b](https://github.com/lekman/magsafe-buskill/commit/91c1d7bb7614a2643ea8a8ef977dc4edc4945d43))
* simplify SonarCloud scanner configuration and update exclusions for better coverage analysis ([d0afe79](https://github.com/lekman/magsafe-buskill/commit/d0afe798bbb99d61cea2fe824be51a8a20180d73))
* update SonarCloud workflow to install SonarScanner and run analysis with coverage reports ([f30dca7](https://github.com/lekman/magsafe-buskill/commit/f30dca7610115fce19bfac99e2be79e2e1742ae5))


### Documentation

* add Changelog link to Quick Links section in README ([67615eb](https://github.com/lekman/magsafe-buskill/commit/67615eb099947f24d7c48e6573cd7d3da526dfb3))
* enhance Snyk policy justification with detailed risk assessment and compliance measures ([2adf543](https://github.com/lekman/magsafe-buskill/commit/2adf543b8bca2ead31dd7028ea225ef6d1fb7c3b))
* expand project task status section in README ([c6a464f](https://github.com/lekman/magsafe-buskill/commit/c6a464fcfdac838ae4127f21635d49d597dff853))
* update README and configuration for improved documentation structure ([3ba2c03](https://github.com/lekman/magsafe-buskill/commit/3ba2c0343ac68157d9cfa1738ddf61ead9025a05))


### Code Refactoring

* rename context variable to avoid naming conflicts and improve clarity in AuthenticationService ([81d8c2d](https://github.com/lekman/magsafe-buskill/commit/81d8c2d3af64a18c01b0a13f9a43de872bc08093))
* resolve SonarCloud issues by renaming variables, reducing cognitive complexity, and improving closure nesting in AuthenticationService ([411147a](https://github.com/lekman/magsafe-buskill/commit/411147aacb5c149761bdcc2850c07e1a6b07338f))


### Tests

* enhance monitoring behavior in PowerMonitorServiceTests to handle immediate stop scenarios ([b870453](https://github.com/lekman/magsafe-buskill/commit/b870453ed1cdf82ba56a5490fa038ac263cd9916))
* enhance multiple callback handling in PowerMonitorServiceTests ([637ef97](https://github.com/lekman/magsafe-buskill/commit/637ef9711e6fdd9ea156c7c504f9568350c8cad4))
* Refactor and enhance MagSafe Guard project ([9167fba](https://github.com/lekman/magsafe-buskill/commit/9167fba0828ab4f8016fe3664e438bb56be70a84))

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
