# Badge Templates

Common shields.io badge patterns for README files. Replace `ORG`, `REPO`, `PACKAGE` with actual values.

## CI/CD Status

```markdown
[![CI](https://github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/ORG/REPO/actions/workflows/ci.yml)
[![Build](https://github.com/ORG/REPO/actions/workflows/build.yml/badge.svg)](https://github.com/ORG/REPO/actions/workflows/build.yml)
[![Tests](https://github.com/ORG/REPO/actions/workflows/test.yml/badge.svg)](https://github.com/ORG/REPO/actions/workflows/test.yml)
```

## Package Registries

### npm

```markdown
![npm version](https://img.shields.io/npm/v/PACKAGE)
![npm downloads](https://img.shields.io/npm/dm/PACKAGE)
![npm bundle size](https://img.shields.io/bundlephobia/minzip/PACKAGE)
```

### PyPI

```markdown
![PyPI version](https://img.shields.io/pypi/v/PACKAGE)
![PyPI downloads](https://img.shields.io/pypi/dm/PACKAGE)
![Python version](https://img.shields.io/pypi/pyversions/PACKAGE)
```

### crates.io (Rust)

```markdown
![crates.io](https://img.shields.io/crates/v/PACKAGE)
![crates.io downloads](https://img.shields.io/crates/d/PACKAGE)
```

## Runtime Requirements

```markdown
![Node](https://img.shields.io/badge/node-%3E%3D18-brightgreen)
![Node](https://img.shields.io/badge/node-%3E%3D20-brightgreen)
![Python](https://img.shields.io/badge/python-%3E%3D3.8-blue)
![Rust](https://img.shields.io/badge/rust-1.70%2B-orange)
```

## Language/Framework

```markdown
![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue)
![JavaScript](https://img.shields.io/badge/JavaScript-ES2022-yellow)
![React](https://img.shields.io/badge/React-18-61DAFB)
![Vue](https://img.shields.io/badge/Vue-3-42b883)
```

## License

```markdown
![License MIT](https://img.shields.io/badge/license-MIT-green)
![License Apache](https://img.shields.io/badge/license-Apache%202.0-blue)
![License GPL](https://img.shields.io/badge/license-GPL%20v3-red)
```

## Code Quality

```markdown
![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen)
![Coverage](https://img.shields.io/codecov/c/github/ORG/REPO)
![Code style](https://img.shields.io/badge/code%20style-prettier-ff69b4)
```

## Custom Static Badges

Pattern: `https://img.shields.io/badge/LABEL-MESSAGE-COLOR`

**Colors:** `brightgreen`, `green`, `yellow`, `orange`, `red`, `blue`, `lightgrey`, `success`, `important`, `critical`, `informational`, `inactive`

**URL encoding:** Replace spaces with `%20`, dashes with `--`, underscores with `__`

```markdown
![Custom](https://img.shields.io/badge/custom-badge-blue)
![Status](https://img.shields.io/badge/status-stable-brightgreen)
![Status](https://img.shields.io/badge/status-beta-yellow)
![Status](https://img.shields.io/badge/status-alpha-orange)
```

## Example Badge Row

```markdown
[![CI](https://github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/ORG/REPO/actions/workflows/ci.yml)
![npm](https://img.shields.io/npm/v/PACKAGE)
![downloads](https://img.shields.io/npm/dm/PACKAGE)
![license](https://img.shields.io/badge/license-MIT-green)
![node](https://img.shields.io/badge/node-%3E%3D18-brightgreen)
```
