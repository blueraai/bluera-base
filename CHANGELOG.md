# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [0.14.2](https://github.com/blueraai/bluera-base/compare/v0.14.1...v0.14.2) (2026-01-18)

### Features

* **statusline:** add timestamped backup before overwriting ([8a83977](https://github.com/blueraai/bluera-base/commit/8a839779d87839fd78dfdc067530e1c545371365))

## [0.14.1](https://github.com/blueraai/bluera-base/compare/v0.14.0...v0.14.1) (2026-01-18)

### Features

* **clean:** harden safety with preview mode and centralized backups ([5dce3fb](https://github.com/blueraai/bluera-base/commit/5dce3fb3bf67eb6aa192e9346c28090ce5b20c57))
* **notify:** add project name to notifications and icon support ([eef953a](https://github.com/blueraai/bluera-base/commit/eef953a0fe6543cc9df6b10aeeee259e7ecbbaa6))

### Bug Fixes

* **notify:** use claude.png icon filename ([3e7342b](https://github.com/blueraai/bluera-base/commit/3e7342bf04bba1a64183bdaa116cca28c8851f84))

## [0.14.0](https://github.com/blueraai/bluera-base/compare/v0.13.0...v0.14.0) (2026-01-18)

### Features

* **cleaner:** add Claude Code Cleaner for diagnosing slow startup ([f9914dd](https://github.com/blueraai/bluera-base/commit/f9914dda5d24cef513441d4ee5c5d981c90ee9cc))
* **config:** add interactive init workflow with feature explanations ([65667c1](https://github.com/blueraai/bluera-base/commit/65667c1d50631c0c5cb6bc5d47f71e1ab46f0b97))
* **statusline:** add preset previews, bluera preset, and ready-to-use scripts ([ea2bde6](https://github.com/blueraai/bluera-base/commit/ea2bde64e753ce4100621f549ca75f17789679dd))

### Bug Fixes

* **readme:** remove @ from mermaid diagram label ([8f4d1df](https://github.com/blueraai/bluera-base/commit/8f4d1df878a417548d79373480b9def5ae45ebde))

## [0.13.0](https://github.com/blueraai/bluera-base/compare/v0.12.1...v0.13.0) (2026-01-17)

### Features

* **.claude:** add repo-specific test-plugin reminder hook ([b5dc2c4](https://github.com/blueraai/bluera-base/commit/b5dc2c43fc9ee881be12231904ed9af19ec37828))
* **release:** add detection script to prefer project scripts ([af7175c](https://github.com/blueraai/bluera-base/commit/af7175c73aa67c18332d5c7c2a6778a06b83ccb9))

## [0.12.1](https://github.com/blueraai/bluera-base/compare/v0.12.0...v0.12.1) (2026-01-17)

## [0.12.0](https://github.com/blueraai/bluera-base/compare/v0.11.7...v0.12.0) (2026-01-17)

### Features

* **init:** add project initialization wizard ([c06869a](https://github.com/blueraai/bluera-base/commit/c06869a949aa9e6f8a41de565d0828f6f9c84ece))

### Bug Fixes

* **release:** monitor ALL workflows by commit SHA ([ceb0648](https://github.com/blueraai/bluera-base/commit/ceb06483a129a1f394667bc2fd067d47813114b8))

## [0.11.7](https://github.com/blueraai/bluera-base/compare/v0.11.6...v0.11.7) (2026-01-17)

### Bug Fixes

* **readme:** restore nested ToC items with linter-friendly anchors ([4c92dd5](https://github.com/blueraai/bluera-base/commit/4c92dd5fefc35c24d56411d8e85ac573a73c678d))

## [0.11.6](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.6) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** detect task runner independently of language ([8607130](https://github.com/blueraai/bluera-base/commit/8607130b783858e0f845efcee9dc6104aba414a9))
* **harden-repo:** distinguish coverage tool vs threshold configuration ([90a8bde](https://github.com/blueraai/bluera-base/commit/90a8bde0444b77f07d0e460651793db2c3a2e5ad))
* **harden-repo:** handle repos with no task runner (uv/pytest direct) ([aa89ef9](https://github.com/blueraai/bluera-base/commit/aa89ef9759938229067ab424f2c22d6af9c75d48))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.5](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.5) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** detect task runner independently of language ([8607130](https://github.com/blueraai/bluera-base/commit/8607130b783858e0f845efcee9dc6104aba414a9))
* **harden-repo:** handle repos with no task runner (uv/pytest direct) ([aa89ef9](https://github.com/blueraai/bluera-base/commit/aa89ef9759938229067ab424f2c22d6af9c75d48))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.4](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.4) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** detect task runner independently of language ([8607130](https://github.com/blueraai/bluera-base/commit/8607130b783858e0f845efcee9dc6104aba414a9))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.3](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.3) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.2](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.2) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.1](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.1) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))

## [0.11.0](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.0) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

## [0.10.2](https://github.com/blueraai/bluera-base/compare/v0.10.1...v0.10.2) (2026-01-17)

### Bug Fixes

* **hooks:** use fully qualified command names in messages ([c7018eb](https://github.com/blueraai/bluera-base/commit/c7018eb4681284880be7449de9b8dece0ef1ab28))

## [0.10.1](https://github.com/blueraai/bluera-base/compare/v0.10.0...v0.10.1) (2026-01-17)

### Bug Fixes

* **explain:** add Algorithm section to ensure output is displayed ([afdd864](https://github.com/blueraai/bluera-base/commit/afdd864c6c03ebdfa579abdbb386a3c1707e6964))

## [0.10.0](https://github.com/blueraai/bluera-base/compare/v0.9.2...v0.10.0) (2026-01-17)

### Features

* **config:** add self-documenting output for show command ([af6b12b](https://github.com/blueraai/bluera-base/commit/af6b12bfb405f20a8118ddd8ce45fb42ac610750))
* **explain:** add /bluera-base:explain command ([80cf30d](https://github.com/blueraai/bluera-base/commit/80cf30d2d2450f6a9c973c4e520dbf9e99724086))
* **lib:** add signals and state library abstractions ([15eb013](https://github.com/blueraai/bluera-base/commit/15eb013f7699355bf49a8650e2eadd6d46fd130b))
* **todo:** add /bluera-base:todo command for task management ([e0bc330](https://github.com/blueraai/bluera-base/commit/e0bc330a8d3d4d403114d2286609ec166e33dfd0))

### Bug Fixes

* **test-plugin:** update counts and add library unit tests ([588c2ca](https://github.com/blueraai/bluera-base/commit/588c2caa82a12a97b1619f70e6280e18225ba9f0))

## [0.9.2](https://github.com/blueraai/bluera-base/compare/v0.9.1...v0.9.2) (2026-01-16)

### Bug Fixes

* **release:** correct shell command parsing in backtick context ([fd6e56b](https://github.com/blueraai/bluera-base/commit/fd6e56b81a9ba94f13086f3d4034537763e8dc79))

## [0.9.1](https://github.com/blueraai/bluera-base/compare/v0.9.0...v0.9.1) (2026-01-16)

## [0.9.0](https://github.com/blueraai/bluera-base/compare/v0.8.1...v0.9.0) (2026-01-16)

### Features

* **settings:** add narrowly scoped permission templates ([b43e813](https://github.com/blueraai/bluera-base/commit/b43e813e9c168ed4672853a12977f5985dddccc5))

## [0.8.1](https://github.com/blueraai/bluera-base/compare/v0.8.0...v0.8.1) (2026-01-16)

### Bug Fixes

* **hooks:** add JSON validation to learning hooks ([16ab3eb](https://github.com/blueraai/bluera-base/commit/16ab3eb02d0d7ce60268dc59c392f88e1db7b6ad))

## [0.8.0](https://github.com/blueraai/bluera-base/compare/v0.7.0...v0.8.0) (2026-01-16)

### Features

* **hooks:** add lint suppression and strict typing checks ([ad43a56](https://github.com/blueraai/bluera-base/commit/ad43a5636066c34048711fc2945a7cdec43800fa))
* **hooks:** add repo hardening with husky, lint-staged, markdownlint ([b0cf141](https://github.com/blueraai/bluera-base/commit/b0cf141075bed228f777418ecdc4c8c6bd5ee479))

### Bug Fixes

* **changelog:** remove duplicate header content ([3daced2](https://github.com/blueraai/bluera-base/commit/3daced21835e011634a85153336a01fb5dc9e20d))
* **hooks:** move observe-learning to PreToolUse for reliable triggering ([8329865](https://github.com/blueraai/bluera-base/commit/83298653e67ebd46b2c2b12bca5378edca7c8a4f))
* quiet lint-staged output and fix hook schema ([45a4bd1](https://github.com/blueraai/bluera-base/commit/45a4bd199970ef3ea0b4b200d389f1c27bf06bcd))

## [0.7.0](https://github.com/blueraai/bluera-base/compare/v0.6.0...v0.7.0) (2026-01-16)

### Features

* **hooks:** add auto-commit hook for session-stop commits ([2645fad](https://github.com/blueraai/bluera-base/commit/2645fad9cd6de36770be731938aee114230c1f73))

## [0.3.0](https://github.com/blueraai/bluera-base/compare/v0.2.3...v0.3.0) (2026-01-16)

### Features

* add /readme command for README.md maintenance ([6ec3abe](https://github.com/blueraai/bluera-base/commit/6ec3abe55adf3cce8c95c3c9ec4b556568d8b4cb))
* **readme:** add breakout subcommand for splitting large READMEs ([a46a12a](https://github.com/blueraai/bluera-base/commit/a46a12a501de7f3dc9c61b64e5bd2ac7e5552144))

### Bug Fixes

* **mermaid:** remove theme config causing GitHub truncation ([4bbdb73](https://github.com/blueraai/bluera-base/commit/4bbdb73ab007f196bfcb1f2ceae5fec815818800))
* **mermaid:** restore node colors using style directives ([34640bb](https://github.com/blueraai/bluera-base/commit/34640bb31ebbcce29b914f544e70169dbdf84ea1))
* **mermaid:** shorten diagram labels to prevent GitHub truncation ([e9c2d2b](https://github.com/blueraai/bluera-base/commit/e9c2d2bfafb80558fbbfddb94ab06045233c3d43))
* **release:** enforce CI-before-tag workflow ([dfdb1b9](https://github.com/blueraai/bluera-base/commit/dfdb1b9b97db18a0aad2fa2938108d80f2188f5c))
* **release:** fetch tags before showing current version ([f0318de](https://github.com/blueraai/bluera-base/commit/f0318de655ce65b8136709c7403efcfb54ed9d91))

## [0.2.3](https://github.com/blueraai/bluera-base/compare/v0.2.2...v0.2.3) (2026-01-15)

## [0.2.2](https://github.com/blueraai/bluera-base/compare/v0.2.1...v0.2.2) (2026-01-15)

## [0.2.1](https://github.com/blueraai/bluera-base/compare/v0.2.0...v0.2.1) (2026-01-15)

### Bug Fixes

* **hooks:** remove unused RED variable in session-setup.sh ([bbb73ab](https://github.com/blueraai/bluera-base/commit/bbb73abd7ee6f6700e91ed2db4814532ed9aef07))

## 0.2.0 (2026-01-15)

### Features

* add CLAUDE.md maintainer command and skill ([811ed07](https://github.com/blueraai/bluera-base/commit/811ed07c2db16a3088c2936edac76ca940ddd483))
* add rule templates and /install-rules command ([f7f3532](https://github.com/blueraai/bluera-base/commit/f7f3532888bd8112e35819f6b89645b6ac7c2c0a))
* **hooks:** add SessionStart hook and cross-platform notifications ([a6e7e56](https://github.com/blueraai/bluera-base/commit/a6e7e5639a32e307081cd66c6bd17de86b86444c))
* initial bluera-base plugin ([451b099](https://github.com/blueraai/bluera-base/commit/451b099e7ebd455411592658bfeab623a98e858d))

### Bug Fixes

* add local_CLAUDE.local.md template ([f590cea](https://github.com/blueraai/bluera-base/commit/f590cea03ad6f2b3083afccd39cb9683e9c4e160))
* **commit:** enforce mandatory workflow steps ([df25d57](https://github.com/blueraai/bluera-base/commit/df25d57478f82e59592103b66f15b10b934f0eb7))
* **commit:** simplify to match working zark-backend pattern ([95d9438](https://github.com/blueraai/bluera-base/commit/95d9438195fbf6f98ade67c6988c02a622a7f1c9))
* **hooks:** critical bug fixes for hook reliability ([7d5540a](https://github.com/blueraai/bluera-base/commit/7d5540ae71f8681a09a77e0eed3640d9a63c7d32))
* **hooks:** remove pathspec excludes causing git errors ([e279361](https://github.com/blueraai/bluera-base/commit/e279361205a7e517b0e48dcc8f44713cfb82a38e))
* **hooks:** resolve shellcheck warnings ([255db02](https://github.com/blueraai/bluera-base/commit/255db0272e041c669eb741251e477ae0701a6bac))
