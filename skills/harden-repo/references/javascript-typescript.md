# JavaScript/TypeScript

Quality tooling for JavaScript and TypeScript projects.

---

## Linting: ESLint

```bash
# Install
npm install -D eslint @eslint/js typescript-eslint

# Config: eslint.config.js (flat config)
```

**Recommended rules:**

- `@typescript-eslint/no-unused-vars`
- `@typescript-eslint/no-explicit-any`
- `no-console` (warn)

---

## Formatting: Prettier

```bash
npm install -D prettier eslint-config-prettier
```

**.prettierrc:**

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}
```

---

## Type Checking: TypeScript

```bash
npm install -D typescript
```

**tsconfig.json strict options:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

---

## Git Hooks: husky + lint-staged

```bash
npm install -D husky lint-staged
npx husky init
```

**package.json:**

```json
{
  "lint-staged": {
    "*.{js,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

**.husky/pre-commit:**

```bash
npx lint-staged
```

---

## Coverage: c8

```bash
npm install -D c8
```

**.c8rc.json:**

```json
{
  "check-coverage": true,
  "lines": 80,
  "branches": 80,
  "functions": 80,
  "statements": 80,
  "reporter": ["text", "lcov", "html"],
  "exclude": ["**/*.test.{js,ts}", "**/*.spec.{js,ts}", "node_modules/**"]
}
```

**package.json script:**

```json
{
  "scripts": {
    "test:coverage": "c8 npm test"
  }
}
```
