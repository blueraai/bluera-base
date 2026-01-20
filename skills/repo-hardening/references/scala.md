# Scala

Quality tooling for Scala projects.

---

## Linting: scalafix

**project/plugins.sbt:**

```scala
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.11.1")
```

**.scalafix.conf:**

```hocon
rules = [
  RemoveUnused,
  DisableSyntax,
  OrganizeImports
]
DisableSyntax.noVars = true
DisableSyntax.noNulls = true
```

---

## Formatting: scalafmt

**project/plugins.sbt:**

```scala
addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.5.2")
```

**.scalafmt.conf:**

```hocon
version = 3.7.17
runner.dialect = scala3
maxColumn = 120
align.preset = more
rewrite.rules = [SortImports, RedundantBraces]
```

---

## Git Hooks: Native

**.git/hooks/pre-commit:**

```bash
#!/bin/sh
sbt scalafmtCheckAll || exit 1
sbt "scalafix --check" || exit 1
```

---

## Coverage: scoverage

**project/plugins.sbt:**

```scala
addSbtPlugin("org.scoverage" % "sbt-scoverage" % "2.0.9")
```

**build.sbt:**

```scala
coverageMinimumStmtTotal := 80
coverageFailOnMinimum := true
coverageExcludedPackages := "<empty>;.*\\.generated\\..*"
```

**Run:** `sbt coverage test coverageReport`
