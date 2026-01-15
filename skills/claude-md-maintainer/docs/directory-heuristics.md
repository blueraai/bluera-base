# Directory Heuristics

Rules for determining which directories should have their own `CLAUDE.md`.

## Module Root Detection

A directory is a **module root** if it contains one of:

| Marker File | Language/Build System |
|-------------|----------------------|
| `package.json` | Node.js / JavaScript |
| `pyproject.toml` | Python (modern) |
| `requirements.txt` | Python (legacy) |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pom.xml` | Java (Maven) |
| `build.gradle` | Java/Kotlin (Gradle) |
| `Makefile` | Make |
| `CMakeLists.txt` | CMake |

## Exclusion Rules

**Never create CLAUDE.md in:**
- `.git/`
- `node_modules/`
- `.venv/` or `venv/`
- `dist/`, `build/`, `out/`
- `target/` (Rust/Maven)
- `vendor/`
- `.idea/`, `.vscode/`
- `__pycache__/`
- `coverage/`

## Monorepo Conventions

Prefer creating module CLAUDE.md for directories that:
- Are under conventional roots: `packages/`, `apps/`, `services/`, `libs/`
- Have their own CI workflow path filters
- Have a manifest file (see table above)

## Hard Cap

If > 25 module roots are detected:
1. Create root `CLAUDE.md`
2. Create `CLAUDE.md` at each top-level monorepo bucket summarizing navigation
3. Defer per-package creation (report as follow-up, not auto-write)

## Priority Order

When deciding where to create:
1. Root `CLAUDE.md` - always first
2. `CLAUDE.local.md` - for personal notes
3. Top-level monorepo buckets (`packages/CLAUDE.md`, etc.)
4. Individual module roots (if under threshold)
