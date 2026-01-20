# Go

Quality tooling for Go projects.

---

## Linting: golangci-lint

```bash
# Install
go install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest
```

**.golangci.yml:**

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports

linters-settings:
  gofmt:
    simplify: true
```

---

## Formatting: gofmt/goimports

```bash
# Built into Go
go fmt ./...
```

---

## Git Hooks: Native

**.git/hooks/pre-commit:**

```bash
#!/bin/sh
go fmt ./... || exit 1
golangci-lint run || exit 1
```

---

## Coverage: go test (built-in)

```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

**Threshold check script:**

```bash
#!/bin/sh
COVERAGE=$(go test -coverprofile=coverage.out ./... 2>&1 | grep -o 'coverage: [0-9.]*%' | grep -o '[0-9.]*')
THRESHOLD=80
if [ "$(echo "$COVERAGE < $THRESHOLD" | bc -l)" -eq 1 ]; then
  echo "Coverage $COVERAGE% is below $THRESHOLD%"
  exit 1
fi
```
