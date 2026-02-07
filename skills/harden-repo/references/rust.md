# Rust

Quality tooling for Rust projects.

---

## Linting: clippy

```bash
# Built into rustup
rustup component add clippy
```

**Cargo.toml:**

```toml
[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"
```

---

## Formatting: rustfmt

```bash
rustup component add rustfmt
```

**rustfmt.toml:**

```toml
edition = "2021"
max_width = 100
tab_spaces = 4
```

---

## Git Hooks: Native

**.git/hooks/pre-commit:**

```bash
#!/bin/sh
cargo fmt --check || exit 1
cargo clippy -- -D warnings || exit 1
```

---

## Coverage: cargo-tarpaulin

```bash
cargo install cargo-tarpaulin
```

**Run with threshold:**

```bash
cargo tarpaulin --fail-under 80
```

**Optional config: tarpaulin.toml**

```toml
[general]
fail-under = 80
out = ["Lcov", "Html"]
skip-clean = true
```
