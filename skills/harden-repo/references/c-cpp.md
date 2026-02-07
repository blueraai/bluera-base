# C/C++

Quality tooling for C and C++ projects.

---

## Linting: clang-tidy

**.clang-tidy:**

```yaml
Checks: >
  -*,
  bugprone-*,
  clang-analyzer-*,
  cppcoreguidelines-*,
  modernize-*,
  performance-*,
  readability-*
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
```

**CMakeLists.txt integration:**

```cmake
find_program(CLANG_TIDY clang-tidy)
if(CLANG_TIDY)
    set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY})
endif()
```

---

## Formatting: clang-format

**.clang-format:**

```yaml
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 120
AllowShortFunctionsOnASingleLine: Inline
BreakBeforeBraces: Attach
```

---

## Git Hooks: Native

**.git/hooks/pre-commit:**

```bash
#!/bin/sh
find src -name '*.cpp' -o -name '*.h' | xargs clang-format --dry-run --Werror || exit 1
find src -name '*.cpp' | xargs clang-tidy -- -std=c++17 || exit 1
```

---

## Coverage: gcov/lcov

**CMakeLists.txt:**

```cmake
option(COVERAGE "Enable coverage" OFF)
if(COVERAGE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
endif()
```

**Generate report:**

```bash
./tests  # run tests
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage-html
```

**Threshold check:**

```bash
#!/bin/sh
COVERAGE=$(lcov --summary coverage.info 2>&1 | grep 'lines' | grep -o '[0-9.]*%' | head -1 | sed 's/%//')
if [ "$(echo "$COVERAGE < 80" | bc -l)" -eq 1 ]; then
  echo "Coverage $COVERAGE% is below 80%"
  exit 1
fi
```
