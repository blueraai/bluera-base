# Kotlin

Quality tooling for Kotlin projects.

---

## Linting: detekt

**build.gradle.kts:**

```kotlin
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.4"
}

detekt {
    config.setFrom("detekt.yml")
    buildUponDefaultConfig = true
}
```

**detekt.yml:**

```yaml
complexity:
  LongMethod:
    threshold: 60
style:
  MaxLineLength:
    maxLineLength: 120
```

---

## Formatting: ktlint

**build.gradle.kts:**

```kotlin
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0"
}
```

**Run:** `./gradlew ktlintFormat`

---

## Coverage: Kover

**build.gradle.kts:**

```kotlin
plugins {
    id("org.jetbrains.kotlinx.kover") version "0.7.6"
}

koverReport {
    verify {
        rule {
            minBound(80)
        }
    }
}
```
