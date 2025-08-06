# Changelog

All notable changes to MagSafe Guard will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This changelog is automatically maintained by release-please -->
<!-- Do not manually edit below this line -->

## [1.11.0](https://github.com/lekman/magsafe-buskill/compare/v1.10.0...v1.11.0) (2025-08-05)


### Features

* add AI agent configuration and context file to version control ([6942fad](https://github.com/lekman/magsafe-buskill/commit/6942fad3cdbac7cfa2d688529d02e403b083e8c5))
* add AI agent justifications system and update agents ([83e9bb8](https://github.com/lekman/magsafe-buskill/commit/83e9bb851e84da645d09d8fc12f3b13edf71cc57))
* add ai-review task to consolidate AI agent findings and prioritize issues ([17c66ea](https://github.com/lekman/magsafe-buskill/commit/17c66ead737e03aa7fd0cd8f1cfda3d438d30d82))
* add configuration and instructions for AI Code agents ([195310e](https://github.com/lekman/magsafe-buskill/commit/195310e409a53a20bff98dd652dd115085e19647))
* improve AI agent tasks with silent mode and markdown linting ([286dbc7](https://github.com/lekman/magsafe-buskill/commit/286dbc760a13c72a2b2584560bd38ad073b394fd))
* **logging:** add Sentry test event functionality and setup documentation ([c2eb825](https://github.com/lekman/magsafe-buskill/commit/c2eb825853268c02af3e83d50287bfafd8c4177f))
* **logging:** enhance Sentry integration with automatic initialization and advanced logging methods ([5502af7](https://github.com/lekman/magsafe-buskill/commit/5502af7e994c68f71f784f325ba2daa44209fa58))
* **logging:** integrate Sentry error tracking and monitoring ([8892a66](https://github.com/lekman/magsafe-buskill/commit/8892a664fe91cc8d99ca4abf70837ae75f705304))
* **security:** implement resource protection with rate limiting and circuit breaker ([0a29e7f](https://github.com/lekman/magsafe-buskill/commit/0a29e7f241769a8e9d25073141d6f4c588cbe7bf))
* **tests:** add JUnit XML generation for test execution reporting and integrate with Codecov ([c68240b](https://github.com/lekman/magsafe-buskill/commit/c68240b639d5c06fada404453e50a1198d9dd54b))
* update .gitignore to exclude coverage files and add justifications file; create PRD template with structured guidelines ([e000ab5](https://github.com/lekman/magsafe-buskill/commit/e000ab53e520fe58a013b3547911314796c10103))


### Bug Fixes

* **actions:** update cache actions to use specific commit SHAs ([2750724](https://github.com/lekman/magsafe-buskill/commit/27507247a7581c9beffaafcf97302d6bd0dd7fa3))
* address security issue in CodeQL workflow ([b7594ab](https://github.com/lekman/magsafe-buskill/commit/b7594ab2ce32e5af49aade1569638a1c443843da))
* **ci:** correct duplicate SHA comments in GitHub Actions ([ad13fff](https://github.com/lekman/magsafe-buskill/commit/ad13fffc2abc7ec7bf173f2f558a399561de15df))
* **ci:** replace Python script with awk for generating JUnit XML from Swift test output ([072bfeb](https://github.com/lekman/magsafe-buskill/commit/072bfebc6b2688b5d9d7916fe403500183ad895f))
* **ci:** update security:pin-actions task to handle already-pinned actions correctly ([9d87dd2](https://github.com/lekman/magsafe-buskill/commit/9d87dd2094e77878b3258c9ad5308f37c140e1e8))
* **ci:** use correct version tag for codecov test-results-action ([a1df553](https://github.com/lekman/magsafe-buskill/commit/a1df553d88b61d44ed9bc0ca87b5eeda7f09d689))
* correct SonarCloud coverage file paths for proper path matching ([eabfa99](https://github.com/lekman/magsafe-buskill/commit/eabfa991b5e485cf8733caa5f1cdd35cb960dddf))
* ensure coverage.xml is always copied to project root for SonarCloud ([5df587d](https://github.com/lekman/magsafe-buskill/commit/5df587d4ec5abe4fa3e6a38880495685518169f3))
* **logging:** improve privacy scrubbing regex patterns in SentryLogger and update SBOM metadata ([4a85f56](https://github.com/lekman/magsafe-buskill/commit/4a85f566081c04dd85f4834cf34796723079734e))
* **logging:** update SentryLogger to clarify intentional hardcoded DSN and improve privacy scrubbing regex comments ([9435507](https://github.com/lekman/magsafe-buskill/commit/94355077fd23ca575996130d0540e80bd862ea4f))
* resolve CI/CD issues with SonarCloud coverage and CodeQL analysis ([e77ad9e](https://github.com/lekman/magsafe-buskill/commit/e77ad9e96db94c8deeebb33c8e1804655ae35bf4))
* revert coverage.xml paths to project root format for SonarCloud ([0f2a79c](https://github.com/lekman/magsafe-buskill/commit/0f2a79c612c977bb3c00a68b7d66bb1bc632a7d1))
* **security:** comprehensive security enhancements for script execution ([cd89965](https://github.com/lekman/magsafe-buskill/commit/cd89965b2f590d122b9d8e1f1f26da5bcb61c31e))
* **security:** improve pin-actions task to skip already-pinned actions ([da5f561](https://github.com/lekman/magsafe-buskill/commit/da5f561e39ed9108efa0078a07a70e1e012b183e))
* **security:** resolve critical command injection vulnerabilities in MacSystemActions ([95a7650](https://github.com/lekman/magsafe-buskill/commit/95a7650d55f988a5dffbbfa73d1365b60f7d0288))
* **sentry:** resolve SonarCloud code smells for hardcoded URIs ([e94b1d0](https://github.com/lekman/magsafe-buskill/commit/e94b1d083d1844132d0c2c6095c4c49ad10bffc0))
* update AI agent tasks to handle file writing properly ([e0b813d](https://github.com/lekman/magsafe-buskill/commit/e0b813ddb970dd9c6c62fd6f389cb3b3bb996483))
* update justifications and agent setup instructions for clarity and formatting ([cca638e](https://github.com/lekman/magsafe-buskill/commit/cca638e72d89d3d90b59d1ac3d41397205f8ab85))
* update warnings on code smells from sonar ([3f08845](https://github.com/lekman/magsafe-buskill/commit/3f08845f74c869f1124afe2484cc1814a6fb1e6c))


### Security Updates

* Addresses Semgrep finding yaml.github-actions.security.run-shell-injection ([b7594ab](https://github.com/lekman/magsafe-buskill/commit/b7594ab2ce32e5af49aade1569638a1c443843da))


### Documentation

* Add comprehensive documentation templates and best practices ([5800668](https://github.com/lekman/magsafe-buskill/commit/5800668f1b830cd59b8abb6965087b1d1210a6d9))


### Code Refactoring

* rename ai-review task to review for clarity ([f40c244](https://github.com/lekman/magsafe-buskill/commit/f40c244eb9a105b97df8bcd7cfdc1dfea9d1477a))


### Tests

* add validation tests for negative shutdown and action delays in SecurityActionUseCase ([42279c1](https://github.com/lekman/magsafe-buskill/commit/42279c1d46d5540504dcf09a7491a2a962a6fe9c))
* Enhance SentryLogger tests and configurations; improve security practices ([641bc9a](https://github.com/lekman/magsafe-buskill/commit/641bc9a7316b583644d27ac8e2f8fbf408a796eb))
* **logging:** enhance LoggerTests and SentryLoggerTests for CI compatibility and coverage reporting ([50fca2a](https://github.com/lekman/magsafe-buskill/commit/50fca2add285bdb459e86a316de9454f54508ce0))

## [1.10.0](https://github.com/lekman/magsafe-buskill/compare/v1.9.0...v1.10.0) (2025-08-03)


### Features

* add iCloud sync functionality for settings ([b21b885](https://github.com/lekman/magsafe-buskill/commit/b21b8851a3943d4d03138a456ec15749136e5333))
* **ci:** add Taskfile caching action for all workflows ([b1a174f](https://github.com/lekman/magsafe-buskill/commit/b1a174f80ef79b71175e80e7d56d3996b1907599))
* **ci:** implement CI test strategies to avoid permission dialogs ([ce7bf7f](https://github.com/lekman/magsafe-buskill/commit/ce7bf7fe06a62f27469354527a0ef3b87a55c592))
* **ci:** implement Swift Package Manager for CI testing ([aab189e](https://github.com/lekman/magsafe-buskill/commit/aab189eeee35c71c67e8d47dc3338f3c1e3c92f8))
* **ci:** migrate all CI workflows from macOS to Ubuntu ([3e13a6e](https://github.com/lekman/magsafe-buskill/commit/3e13a6e96c81c6593e2a8896aa4861500f9b09d7))
* enhance iCloud sync functionality and update feature flag management ([203c4cb](https://github.com/lekman/magsafe-buskill/commit/203c4cb2a171775c27a90e1fe2c3aaefb5634ba8))
* Implement robust logging and error handling in SyncService; refactor CloudKit initialization and sync methods for improved stability and performance. Update UserDefaultsManager to defer sync service initialization, ensuring proper settings loading. Enhance CloudSyncSettingsView to manage sync state effectively and prevent crashes during UI updates. Add comprehensive crash prevention and debugging guides for maintainers. ([6f3b470](https://github.com/lekman/magsafe-buskill/commit/6f3b470d2bf8e68dcacd2c61704503769a9ce375))
* migrate project to Xcode structure with CloudKit integration ([f41f6ee](https://github.com/lekman/magsafe-buskill/commit/f41f6ee9e3deaff110eac936a3444619b91e0a5a))
* **taskfile:** add run IDs to git:runs:check table output ([0520732](https://github.com/lekman/magsafe-buskill/commit/05207320e5bc58d5ada4c6c6c3cbc6c8c07a971e))
* update settings UI to use sidebar navigation and enhance iCloud sync settings ([2dcadc4](https://github.com/lekman/magsafe-buskill/commit/2dcadc4ff26104e2cb9542ca0fb083e0bdc74376))


### Bug Fixes

* add cache-key-suffix to Setup Swift Build Environment step in CodeQL workflow ([62960da](https://github.com/lekman/magsafe-buskill/commit/62960da9cc8f3635cba63a20b5fa21b0846dd753))
* add CI-specific build scheme and update test commands to use it ([dd730a6](https://github.com/lekman/magsafe-buskill/commit/dd730a63bc00df86791d2932ec0afe3d33833c37))
* add missing completion parameter to disarm calls in tests ([66331e7](https://github.com/lekman/magsafe-buskill/commit/66331e7f1bab5e6e153dab8fecd70238f0cd4ce7))
* address Swift linting issues and format code ([627090f](https://github.com/lekman/magsafe-buskill/commit/627090f491bee5c339bd96f3d6f92cf2d21145f9))
* apply SwiftLint auto-fixes and markdown formatting ([5cb47f2](https://github.com/lekman/magsafe-buskill/commit/5cb47f28023371350d566b059b21070fd43ade27))
* **build:** remove invalid exclude parameter from Package.swift ([270ed3c](https://github.com/lekman/magsafe-buskill/commit/270ed3cda60bf0665ec7c1c133a3ed3141ee81ff))
* **build:** specify explicit destination to avoid xcodebuild warnings ([e95121f](https://github.com/lekman/magsafe-buskill/commit/e95121fc4e588cf2b9c2537bef54425196d7203e))
* **ci:** add CI-specific flags to build tasks to prevent hanging ([43772cb](https://github.com/lekman/magsafe-buskill/commit/43772cbae3f0c055b7fbfecbaf87716772602955))
* **ci:** add timeout and quiet mode to prevent xcodebuild hanging ([910e312](https://github.com/lekman/magsafe-buskill/commit/910e3121921f319a8bac2584f05ee139c4bec401))
* **ci:** add xcodeproj files required for CI builds ([ebdaf77](https://github.com/lekman/magsafe-buskill/commit/ebdaf775fb07bd95ba4702514c38b7ac48d30cf3))
* **ci:** clean up workflows for successful CI/CD execution ([88de410](https://github.com/lekman/magsafe-buskill/commit/88de410aa6fcb1c64b02c8272a9087890bd56917))
* **ci:** correct Swift Bundler download URL and method ([5b3ad52](https://github.com/lekman/magsafe-buskill/commit/5b3ad529aa5bd24c9354652f5be6d2a646db88e3))
* **ci:** correct YAML syntax in test-local.yml ([aa692f2](https://github.com/lekman/magsafe-buskill/commit/aa692f26dc032d2b1db5d9a4d43bf23474e53688))
* **ci:** disable code signing for tests in CI environment ([50ab431](https://github.com/lekman/magsafe-buskill/commit/50ab431a18e165f0b49607cd3b692fef9a2b16ab))
* **ci:** disable sandbox/hardened runtime and skip UI tests in CI ([fc8afa4](https://github.com/lekman/magsafe-buskill/commit/fc8afa4942592104868cd3e2ce873320f93da2d3))
* **ci:** disable TEST_HOST and BUNDLE_LOADER to prevent app launch ([5fddd8d](https://github.com/lekman/magsafe-buskill/commit/5fddd8de9c11ae268e44c520d20cab357f819299))
* **ci:** disable tests in CI and simplify CodeQL for immediate merge ([8978b4f](https://github.com/lekman/magsafe-buskill/commit/8978b4fd69596c35111e52220db2ae64e9fc8ca7))
* **ci:** fix CodeCov and CodeQL configurations ([83d7770](https://github.com/lekman/magsafe-buskill/commit/83d77701d34fb2c74ebf4039effe5915164a4d03))
* **ci:** fix sonar:convert task to work with SPM-based testing ([d97dd9a](https://github.com/lekman/magsafe-buskill/commit/d97dd9a41ce3756ff91cece305dd8bcc44c643ba))
* **ci:** handle ARM Mac Rosetta issues in setup-swift-build action ([510a64c](https://github.com/lekman/magsafe-buskill/commit/510a64ce39556fb723dec16fc638247a12616e5d))
* **ci:** handle xcodebuild broken pipe errors in swift action ([fe1a66d](https://github.com/lekman/magsafe-buskill/commit/fe1a66dd2100a843cfb4992d917d1208f26b1cf6))
* **ci:** improve xcodebuild error handling and output capture in CI ([2096cf2](https://github.com/lekman/magsafe-buskill/commit/2096cf2a973e7b10882e98adcaa3fdaa3a4f0397))
* **ci:** limit tests to safe subset that don't trigger system dialogs ([73a790e](https://github.com/lekman/magsafe-buskill/commit/73a790e37ed4e3a2f59c4d253734d8a2e4756ceb))
* **ci:** prevent location permission dialogs during CI tests ([32a3638](https://github.com/lekman/magsafe-buskill/commit/32a3638510797380b5fe37c8dc1c0f6c7ccd2206))
* **ci:** remove build operations from Swift setup action ([4aee356](https://github.com/lekman/magsafe-buskill/commit/4aee35677319537b2ceab88e67678ec4b1cfa02b))
* **ci:** remove deprecated add-snippets parameter from CodeQL action ([57caf88](https://github.com/lekman/magsafe-buskill/commit/57caf885349a19cba3194f1e8fcbb5b5a71890a9))
* **ci:** remove missing swift:setup-bundler dependency and inline bundler setup ([ede211c](https://github.com/lekman/magsafe-buskill/commit/ede211cd2bcb8edbbbb60fe25d89539efcfb4925))
* **ci:** remove TEST_HOST/BUNDLE_LOADER and add MAGSAFE_GUARD_TEST_MODE env var ([767c2a1](https://github.com/lekman/magsafe-buskill/commit/767c2a15172dda8c937c9640c01ee82ae0876470))
* **ci:** remove timeout command for macOS compatibility ([b4f36ac](https://github.com/lekman/magsafe-buskill/commit/b4f36ac453424bbfae9fd8444fbb10698537707e))
* **ci:** replace deprecated save-always with separate restore/save steps ([c4989e1](https://github.com/lekman/magsafe-buskill/commit/c4989e1334e5c80b09af4eaf622d9d9e86d0043c))
* **ci:** resolve CodeQL cache miss and key conflicts ([ab6ed7e](https://github.com/lekman/magsafe-buskill/commit/ab6ed7eed267d07c83b2aaca656ad19faa2a6766))
* **ci:** resolve test workflow failures with consistent scheme usage ([bfbda7a](https://github.com/lekman/magsafe-buskill/commit/bfbda7a47c3390f65ed9b0de7d724bbcc6a2f13c))
* **ci:** simplify test execution to use xcodebuild test directly ([141b4c6](https://github.com/lekman/magsafe-buskill/commit/141b4c6c7a23b27507baa50b53ea61b90595d4c6))
* **ci:** switch from Ubuntu to macOS runners for Swift analysis ([059fdbe](https://github.com/lekman/magsafe-buskill/commit/059fdbe77e4f2b10cf05a22eaf6e5a7751a5602c))
* **ci:** update build-sign workflow to use Swift Bundler and fix sign tasks ([5f0afa0](https://github.com/lekman/magsafe-buskill/commit/5f0afa0c4e1b7f4f3aaa1dabfb0c9c5f7474fc6e))
* **ci:** update cache action to v4.2.0 to fix deprecated version error ([7da62ee](https://github.com/lekman/magsafe-buskill/commit/7da62ee64ca3cc00e53f167239a86b38664dac08))
* **ci:** update cache actions to use v4 tag instead of deprecated SHAs ([206d7c1](https://github.com/lekman/magsafe-buskill/commit/206d7c1846a6232f0fc350d5ab91c8bb13f91daa))
* **ci:** update CodeQL workflow to use xcodebuild for Xcode project ([bf788f6](https://github.com/lekman/magsafe-buskill/commit/bf788f6e59df31d37f8bfcff6fef3974abd7d211))
* **ci:** update GitHub workflows to use correct task names and fix PIPESTATUS bash array usage ([43ba8e6](https://github.com/lekman/magsafe-buskill/commit/43ba8e695e6e061040bf627b44104d1ba7285738))
* **ci:** update Swift version to 5.10 for Ubuntu compatibility ([4083fab](https://github.com/lekman/magsafe-buskill/commit/4083fabb0f21331a287bb8642f44662225c7027b))
* **ci:** update swift-actions/setup-swift to v2 to fix GPG error ([30b581d](https://github.com/lekman/magsafe-buskill/commit/30b581dd4c922d5efb54ad2a0293be26036bcb03))
* **ci:** update test.yml to use sonar CLI directly on macOS ([db9bd15](https://github.com/lekman/magsafe-buskill/commit/db9bd1598ecac323bad7c3fa9f63011ba3164a42))
* **ci:** use direct xcodebuild for CodeQL to avoid build hangs ([dc3d799](https://github.com/lekman/magsafe-buskill/commit/dc3d79935413c3e386d1e8133887102ba2f80072))
* **ci:** use local action reference for cache-taskfile in setup-swift-build ([5345ce2](https://github.com/lekman/magsafe-buskill/commit/5345ce29894ac2114b72ed7c825880057517a0ea))
* **codeql:** always build for CodeQL analysis to fix 'no source code seen' error ([3a57715](https://github.com/lekman/magsafe-buskill/commit/3a57715ee705c07529b8987d7ec6f26468eb6811))
* correct syntax for cache-key-suffix in Setup Swift Build Environment action ([5a89b81](https://github.com/lekman/magsafe-buskill/commit/5a89b811eba7b52be1ae0f5f4f2fd8426b9d4048))
* implement protocol-based dependency injection for LocationManager ([0b9a843](https://github.com/lekman/magsafe-buskill/commit/0b9a8434fb3bb779e1a78638962eda1ee0888135))
* settings menu item not opening due to missing target ([a5f47c0](https://github.com/lekman/magsafe-buskill/commit/a5f47c0dd67b890ae68bc0af3256982ccae081f0))
* streamline permissions section in CodeQL workflow ([15321b2](https://github.com/lekman/magsafe-buskill/commit/15321b2ec14cc561b11d3717ca5494a61b8c222c))
* **taskfile:** make git:runs:log non-interactive with silent mode ([d1e26e6](https://github.com/lekman/magsafe-buskill/commit/d1e26e680f7317184b94311f5f9c1f298f1fb509))
* **tests:** fix FeatureFlagsTests JSON file tests for CI ([392aaa4](https://github.com/lekman/magsafe-buskill/commit/392aaa4ce1ca400321e9efb1b259c41fd1421e88))
* **tests:** fix FeatureFlagsTests loadFromJSON test ([6e0316c](https://github.com/lekman/magsafe-buskill/commit/6e0316c64325266484429d0341d40010c9a803a0))
* **tests:** make FeatureFlagsTests more robust for CI environment ([f97926c](https://github.com/lekman/magsafe-buskill/commit/f97926c98b4726d9daebf835844395c59243f4fc))
* **tests:** prevent app initialization during test runs ([2a6a02b](https://github.com/lekman/magsafe-buskill/commit/2a6a02b2eca8e10de109d51d873c96f4cb0b02c1))
* **tests:** resolve architecture mismatch and scheme issues in CI tests ([51d40f0](https://github.com/lekman/magsafe-buskill/commit/51d40f0b4b4ac93d2583c444106bd37d071e92b5))
* **tests:** resolve CI test failures with linking and warnings ([ea28c68](https://github.com/lekman/magsafe-buskill/commit/ea28c689106ec97836032f71b767c7e4000d98e7))
* **tests:** use correct LogCategory.general instead of .app ([283dcd9](https://github.com/lekman/magsafe-buskill/commit/283dcd90e3d4df847b066c3427e3e78761fcaf6b))
* **ui:** resolve settings window visibility and environment object issues ([024fd2c](https://github.com/lekman/magsafe-buskill/commit/024fd2c9174b4a9bb7ac970380f8b3c4303b4d26))
* update all remaining references to old naming conventions ([6027b26](https://github.com/lekman/magsafe-buskill/commit/6027b2673febd746a3965ac0ba704ee19bfe1006))
* **workflows:** remove cache key suffixes for Taskfile caching in build-sign, codeql, and test workflows ([ba690c8](https://github.com/lekman/magsafe-buskill/commit/ba690c8e7bce688e35e2aa95e6faac3843e4da17))
* **xcode:** add test targets to MagSafeGuard scheme BuildAction ([aa65a54](https://github.com/lekman/magsafe-buskill/commit/aa65a544c902d993eec2b769359705ec4192f737))


### Performance Improvements

* **ci:** only save taskfile cache when freshly installed ([6bd3a5b](https://github.com/lekman/magsafe-buskill/commit/6bd3a5b79cbed044fdd74c91262b35999ed8b245))
* **ci:** optimize build and test performance to prevent timeouts ([e0db009](https://github.com/lekman/magsafe-buskill/commit/e0db009ad55dcb3f636cd7d93da79bac0edf740b))
* **ci:** optimize CodeQL workflow with enhanced caching ([647e283](https://github.com/lekman/magsafe-buskill/commit/647e283913e6a2ced1699090ac7cd29baa67d759))
* **ci:** use Swift Package Manager for CodeQL builds ([c571474](https://github.com/lekman/magsafe-buskill/commit/c571474a2ffd702a32f4379dfbf37c44eb9c5821))


### Documentation

* add test refactoring plan and remove debug configuration ([600e6fa](https://github.com/lekman/magsafe-buskill/commit/600e6fa52c3b8e257b2be066cd5cf406c89face3))


### Continuous Integration

* add more verbose error output for test failures ([6da1721](https://github.com/lekman/magsafe-buskill/commit/6da17217eb253dc28fbcc1c815fb5dcd1d94b613))
* add verbose output to diagnose test coverage failures ([122b9cc](https://github.com/lekman/magsafe-buskill/commit/122b9cca23c71f1c6d45ee22d08cf0333ca67f6e))
* temporarily disable build-sign workflow ([f183ae7](https://github.com/lekman/magsafe-buskill/commit/f183ae7293a84c58ff4445532b7d2f84fdc93da3))


### Code Refactoring

* **build:** replace Swift Bundler with native xcodebuild task ([cf31a03](https://github.com/lekman/magsafe-buskill/commit/cf31a03e413fcb282cd8d629c0aeb9098af10783))
* **ci:** consolidate Taskfile caching into setup-swift-build action ([2bd8415](https://github.com/lekman/magsafe-buskill/commit/2bd84151f54421f4ed88a8d24d8b1aa9a64f752d))
* **ci:** extract SonarCloud scan to reusable action ([248f541](https://github.com/lekman/magsafe-buskill/commit/248f541f2ca9f8038a954ba26b7f8c5b42614f86))
* **ci:** remove validation and summary steps from Swift setup action ([bd50ddc](https://github.com/lekman/magsafe-buskill/commit/bd50ddc4f0913bdb355cee913e488dc278f809a8))
* **ci:** streamline CI/CD workflows and improve test coverage reporting ([638305e](https://github.com/lekman/magsafe-buskill/commit/638305e336e3e04f315ccbcd822c873860873f59))
* **ci:** update GitHub workflows to use Taskfile ([4c47422](https://github.com/lekman/magsafe-buskill/commit/4c47422e5611c651f930657a297810f6d5d06a30))
* **ci:** use Taskfile commands in CodeQL workflow for consistency ([bb5a555](https://github.com/lekman/magsafe-buskill/commit/bb5a5553f943c2d49cec3f185119e393eaf7d0c5))
* **ci:** use Taskfile for SPM workflows instead of bash scripts ([4d580c6](https://github.com/lekman/magsafe-buskill/commit/4d580c6e267741e03f18ae9db33e855fd2ac7fe6))
* clean up project structure and remove demo functionality ([143b794](https://github.com/lekman/magsafe-buskill/commit/143b79448c64894ba86da6446dc4841f1182fac9))
* code structure for improved readability and maintainability ([b88fc0c](https://github.com/lekman/magsafe-buskill/commit/b88fc0c3bd9380df2229a4c8eb4b8e6a9f6b3f49))
* consolidate workflow actions and implement concurrency for improved efficiency ([7433786](https://github.com/lekman/magsafe-buskill/commit/743378685212dc7464e9a8911da09e22e8f1303d))
* streamline code formatting and improve readability across multiple files ([230fc49](https://github.com/lekman/magsafe-buskill/commit/230fc49c8bb0af7da6f8c7a240245ab15084b578))
* **test:** implement protocol-based dependency injection for location services ([62afba2](https://github.com/lekman/magsafe-buskill/commit/62afba2c5d2b04f6d829d761bf3aa08ec600011f))
* **tests:** migrate tests to Xcode project structure ([cb49d54](https://github.com/lekman/magsafe-buskill/commit/cb49d5495324894f272bfcff3e62063ca36c8ea5))
* update action path for pinning specific composite action ([c8c294e](https://github.com/lekman/magsafe-buskill/commit/c8c294ed11511b23d97c86ff71a2af118741b826))
* **yaml:** reduce verbosity of validation output ([0acf56e](https://github.com/lekman/magsafe-buskill/commit/0acf56ec6d1a1cd1f6be6fa3e14527fb0d6616ce))


### Tests

* **ci:** add individual test runner to identify hanging tests ([4c3260b](https://github.com/lekman/magsafe-buskill/commit/4c3260b7e0750401de944ca9fa625c95057de03e))
* **swift:** add comprehensive unit tests for Logger and FeatureFlags utilities ([31e4b28](https://github.com/lekman/magsafe-buskill/commit/31e4b2896e8aa56c606a9fbd29977ab2f03c66b2))


### Styles

* fix SwiftLint warnings and configuration ([bc49e6f](https://github.com/lekman/magsafe-buskill/commit/bc49e6fc25c1fb477318524ba2cee7a522d1d1ad))
* fix trailing whitespace and YAML formatting ([ee116b1](https://github.com/lekman/magsafe-buskill/commit/ee116b1c0f64f08e6d7089efcfc69efa62c67381))

## [1.9.0](https://github.com/lekman/magsafe-buskill/compare/v1.8.0...v1.9.0) (2025-07-30)


### Features

* add comprehensive code signing infrastructure and improve build tooling ([a3ae4d5](https://github.com/lekman/magsafe-buskill/commit/a3ae4d5cdd00d592138fcf10b92047f1e44ded16))
* add tasks for checking workflow run status and downloading logs ([5509fa8](https://github.com/lekman/magsafe-buskill/commit/5509fa85e8c775eb13c9436f56d68e4719b963bb))
* enhance feature flag management with additional flags and convenience properties ([48d5d64](https://github.com/lekman/magsafe-buskill/commit/48d5d6411879bd2fc14354481f7d04077351db7a))
* enhance security measures for GitHub Actions and fork PRs with comprehensive policies and workflows ([ac44ca5](https://github.com/lekman/magsafe-buskill/commit/ac44ca5b5b1f25078ad0cd2780d2a8a78f81f130))


### Bug Fixes

* **ci:** split artifact upload to handle PR and release builds separately ([6216e08](https://github.com/lekman/magsafe-buskill/commit/6216e088a77129ba31e7384b2444090c5d59805a))
* improve build tooling and make swift tasks generic ([b0e6110](https://github.com/lekman/magsafe-buskill/commit/b0e61108bcc576806f3c9a2dc3ea36637f885456))
* remove unnecessary blank lines in workflow and task files for cleaner code ([b43a0f8](https://github.com/lekman/magsafe-buskill/commit/b43a0f85fbaebc133060316d13881d4579561ba8))
* update build task command to use swift for application build process ([9100ec9](https://github.com/lekman/magsafe-buskill/commit/9100ec9654ef09a448518cb3d262209bffa20ede))
* update Snyk action references in workflows and tasks for improved security scanning ([ad962d1](https://github.com/lekman/magsafe-buskill/commit/ad962d167b5be0c72d790520f8e0a74a634a3115))


### Code Refactoring

* update Swift setup to use custom action and improve caching ([ea944c6](https://github.com/lekman/magsafe-buskill/commit/ea944c65bd56b8e542101eae01f96f493e1a59a6))


### Tests

* add comprehensive unit tests for FeatureFlags ([19137cd](https://github.com/lekman/magsafe-buskill/commit/19137cdb408456f9fd2f121a6c3e28d44bcec7f6))

## [1.8.0](https://github.com/lekman/magsafe-buskill/compare/v1.7.0...v1.8.0) (2025-07-29)


### Features

* add feature flag system with JSON configuration ([4536a5a](https://github.com/lekman/magsafe-buskill/commit/4536a5a8d597f3b827c862d56b4a5445f6ca45a6))
* Enhance accessibility audit results and extend VoiceOver announcement support ([74a49ee](https://github.com/lekman/magsafe-buskill/commit/74a49eefe82e671f99e6fdb7cae510c231fd2e28))


### Bug Fixes

* Improve coverage check logic and add warning for missing coverage data ([5e7982e](https://github.com/lekman/magsafe-buskill/commit/5e7982e1c70a8bbdcfc6e63a32a4cc9c087949bc))
* Update SBOM document namespace and creation timestamp for version 1.6.0-54 ([78ca3aa](https://github.com/lekman/magsafe-buskill/commit/78ca3aab2eba9c41c79961b414bc78749054772c))
* Update SPDX document namespace and creation timestamp for accuracy ([e90a96c](https://github.com/lekman/magsafe-buskill/commit/e90a96c1f4f631a2e7fedc1a5fa760e3e4be3586))
* Update VSCode settings to exclude files and enhance README debug instructions ([009697e](https://github.com/lekman/magsafe-buskill/commit/009697ebc9da8ab6ba74f56f4474b8879f0cbc6b))


### Documentation

* Update README to reflect project transition to Swift Package and enhance development instructions ([9528a1d](https://github.com/lekman/magsafe-buskill/commit/9528a1d516d430e4f3827b9b3bd68ae0ef1a6d4e))


### Code Refactoring

* Enhance system path configuration and accessibility features in MacSystemActions ([7a79f57](https://github.com/lekman/magsafe-buskill/commit/7a79f5769b5280828a358f39363e426c6493c6d0))
* Simplify location removal handling and enhance UI structure in TrustedLocationsView ([dc1071e](https://github.com/lekman/magsafe-buskill/commit/dc1071ee910faefba0814772295b1ed6f8dcfd93))
* Update setup instructions and enhance tool installation messages ([54f0dd4](https://github.com/lekman/magsafe-buskill/commit/54f0dd44f369428508a0b8ae9359c310951045aa))

## [1.7.0](https://github.com/lekman/magsafe-buskill/compare/v1.6.0...v1.7.0) (2025-07-27)


### Features

* Add AppController for managing application state and security actions ([48bdcd6](https://github.com/lekman/magsafe-buskill/commit/48bdcd6e57a7193fef00a7b4124a567dcca374a0))
* Add SonarCloud and Swift development tasks ([143d097](https://github.com/lekman/magsafe-buskill/commit/143d09766f576bff903c370905f9c6a0cd960995))
* Add support for Software Bill of Materials (SBOM) generation and update related files during pre-push hook ([5af2943](https://github.com/lekman/magsafe-buskill/commit/5af2943bf88ae2ec424fa993e8df17ed537a23d4))
* enhance action pinning scripts with GitHub authentication ([ecf87e5](https://github.com/lekman/magsafe-buskill/commit/ecf87e5f452ca94c69d78b8e0eb7a74ca5f38ff1))
* Enhance GitHub Actions workflows and security measures ([607748e](https://github.com/lekman/magsafe-buskill/commit/607748e9022ee44b020d1130fa863bfcc5dced8d))
* Enhance logging privacy by implementing sensitive logging methods and updating documentation ([1593758](https://github.com/lekman/magsafe-buskill/commit/15937585f6b61c710b05b1bd07cd92389df19948))
* Enhance task documentation and streamline task listings for Swift, security, and markdown tasks; add API documentation generation task ([14b640a](https://github.com/lekman/magsafe-buskill/commit/14b640a698f6bef88791a51b4892984da17cbc17))
* Enhance test execution and coverage reporting with parallel execution and improved logging ([84c7f38](https://github.com/lekman/magsafe-buskill/commit/84c7f38ad90ecdbc5c6274cc5cc19d4e471c19c5))
* Implement location-based auto-arm functionality with LocationManager and trusted locations management ([8cf5d34](https://github.com/lekman/magsafe-buskill/commit/8cf5d34029037e29a628bfa0588cc39f8c24070a))
* implement Settings UI and Persistence (Task 7) ([9f76d55](https://github.com/lekman/magsafe-buskill/commit/9f76d55e585b6f2f3cb822aef25f0b841dbfbc09))
* Implement unified logging system using os.log for MagSafe Guard ([86fe601](https://github.com/lekman/magsafe-buskill/commit/86fe601f106f69ab4c3495a7658d04d40c8cc61d))
* Refactor LocationManager and MacSystemActions for improved path handling; enhance TrustedLocationsView and UserDefaultsManager for better UI and functionality ([491ec2d](https://github.com/lekman/magsafe-buskill/commit/491ec2dcff32fb4c2b0af1c4c956e87bf222a7bd))
* **settings:** enhance SettingsView and UserDefaultsManager with improved documentation and code quality ([7e27151](https://github.com/lekman/magsafe-buskill/commit/7e27151df38077238c3b07693a834a4e72613b8d))
* Simplify error handling in AuthenticationService and add swiftlint disable comments for auto-arm related files ([7dedcc7](https://github.com/lekman/magsafe-buskill/commit/7dedcc7ce19d8546013b0a1fcebd213e8322b1cc))
* Update documentation and task files for improved clarity and organization; remove outdated security and sonarcloud guides; enhance markdown and swift task descriptions ([f21d077](https://github.com/lekman/magsafe-buskill/commit/f21d077364b4cc43fed446e363318e7bdc1280ff))
* Update documentation and task files for improved clarity; rename install tasks to setup and enhance SBOM generation instructions ([14d3854](https://github.com/lekman/magsafe-buskill/commit/14d3854dfe57a7f8cf848938ec8ab0012de56466))
* Update documentation, remove obsolete scripts, and add comprehensive tests for NotificationService ([4ff710f](https://github.com/lekman/magsafe-buskill/commit/4ff710f0f5086c244d673baa7a25a76b42352921))
* Update README and SPDX file with new export timestamps and versioning; enhance test task reliability ([ebe0de9](https://github.com/lekman/magsafe-buskill/commit/ebe0de91b2bbb9353b066956bae9e2997db40ce6))


### Bug Fixes

* add explanatory comment for empty MockNotificationDelivery init ([714dc57](https://github.com/lekman/magsafe-buskill/commit/714dc57ebd46c93b828fb30a395d1ace8e997840))
* address SonarCloud code quality issues ([1b6689f](https://github.com/lekman/magsafe-buskill/commit/1b6689f658e48a3a4f372580ba34be032292a5ca))
* correct template image handling in AppDelegate ([12da8f2](https://github.com/lekman/magsafe-buskill/commit/12da8f2410e895c35398115e09d6ddbe4e586bbd))
* correct webiny action SHA and add automated security tooling ([664ef86](https://github.com/lekman/magsafe-buskill/commit/664ef86acd4c849966fe41c2234907a9c2f9d4d0))
* define constant for duplicated app name literal ([f00c2bf](https://github.com/lekman/magsafe-buskill/commit/f00c2bfc95176d9fb53f880cbea9a1cfcec97466))
* Improve comments and enhance exclusions in SonarCloud configuration for better scan performance ([5554714](https://github.com/lekman/magsafe-buskill/commit/55547149598f686649cc186caa3b2678b771f34b))
* remove top-level write permissions from GitHub workflows ([96d08e2](https://github.com/lekman/magsafe-buskill/commit/96d08e2c92d8d725e47f11cd8664f61b5143b3da))
* Remove unnecessary whitespace in MacSystemActions, SettingsView, and TrustedLocationsView; update SPDX file with new document namespace and creation timestamp ([edfe9b1](https://github.com/lekman/magsafe-buskill/commit/edfe9b166ce524f9a8d8e14abf12ecf57b1ed6af))
* replace duplicated literal with constant in AppController ([2649de2](https://github.com/lekman/magsafe-buskill/commit/2649de2fe30109180651a6f133730cbdf1f38e70))
* update AppDelegateCoreTests to work with AppController integration ([e8589d2](https://github.com/lekman/magsafe-buskill/commit/e8589d2ede7dd5d1a83af7d3f5c889ee6339a59a))
* Update Taskmaster export timestamp and adjust SPDX document namespace and creation timestamp ([3441066](https://github.com/lekman/magsafe-buskill/commit/3441066176defa02929b84b744055b79df3ba73f))
* Update Taskmaster export timestamp and enhance coverage report filters in Swift tasks ([2f492dc](https://github.com/lekman/magsafe-buskill/commit/2f492dc4b65693354022ae45f458db221cbbe573))


### Documentation

* update SPDX document namespace and creation timestamp ([12da8f2](https://github.com/lekman/magsafe-buskill/commit/12da8f2410e895c35398115e09d6ddbe4e586bbd))
* update task status and adjust progress metrics in README ([7e73cd8](https://github.com/lekman/magsafe-buskill/commit/7e73cd8ae740450008f69ff1661379022c749670))
* update task status and progress metrics in README ([1a7b298](https://github.com/lekman/magsafe-buskill/commit/1a7b29864a2a4cdfb6aa04b8152cf402c3ffc226))
* update task status and remove Figma resources from documentation ([1a6006d](https://github.com/lekman/magsafe-buskill/commit/1a6006d9e5dec8530de1e59d8c085f5e61138810))


### Code Refactoring

* Clean up authentication_check disabling comments and update SPDX file with new document namespace and creation timestamp ([6a081ac](https://github.com/lekman/magsafe-buskill/commit/6a081acf5fb1b2728fc52e48386f604008205e27))
* clean up whitespace in various files for consistency ([12da8f2](https://github.com/lekman/magsafe-buskill/commit/12da8f2410e895c35398115e09d6ddbe4e586bbd))
* enhance readability of authentication method parameters ([12da8f2](https://github.com/lekman/magsafe-buskill/commit/12da8f2410e895c35398115e09d6ddbe4e586bbd))
* extract trusted networks and custom scripts list into separate views for improved readability ([d3f9856](https://github.com/lekman/magsafe-buskill/commit/d3f9856e49c104d60cd1d7bbd6968a5abb9b97ab))
* modularize General and Security settings UI components for improved readability ([9244369](https://github.com/lekman/magsafe-buskill/commit/92443696e18240d68360c30d0751313813d88684))
* **settings:** modularize available actions and auto-arm settings for improved readability ([7ce5d68](https://github.com/lekman/magsafe-buskill/commit/7ce5d6876a7a010671cdc632ffc0dfb8a78ccd38))
* **settings:** modularize General and Auto-Arm settings views for improved readability ([e636c5f](https://github.com/lekman/magsafe-buskill/commit/e636c5f9669be481a6f20bd6e16413e0b1927d2c))
* update SwiftLint rules and configurations for improved code quality ([12da8f2](https://github.com/lekman/magsafe-buskill/commit/12da8f2410e895c35398115e09d6ddbe4e586bbd))


### Tests

* enhance AppController and NotificationService tests for grace period and settings integration ([6da63fc](https://github.com/lekman/magsafe-buskill/commit/6da63fce582a59c8ace3f757b54e6ffba2af620c))

## [1.6.0](https://github.com/lekman/magsafe-buskill/compare/v1.5.0...v1.6.0) (2025-07-26)


### Features

* Add LCOV format generation for Codecov coverage reports ([94c19c2](https://github.com/lekman/magsafe-buskill/commit/94c19c2053cbe17329de5e17bc33b10295439766))
* Add Software Bill of Materials (SBOM) support for security compliance and dependency tracking ([f7b6c97](https://github.com/lekman/magsafe-buskill/commit/f7b6c97dfbcda4c622eea0a944be09b529163411))
* Add step to find LCOV files for coverage upload ([d014072](https://github.com/lekman/magsafe-buskill/commit/d0140724accd41fe90258ad015ec3bbb66372a77))
* Enhance documentation with new tests for menu bar UI and accessibility features ([65cc92a](https://github.com/lekman/magsafe-buskill/commit/65cc92a65db860715da68cd178d73b14b28e6461))
* Update status icon to use shield SF Symbols for better visual representation ([f0febe7](https://github.com/lekman/magsafe-buskill/commit/f0febe7671637a5f0a41a9bcdb71d553372ee30d))

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
