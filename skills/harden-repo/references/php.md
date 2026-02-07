# PHP

Quality tooling for PHP projects.

---

## Linting + Type Checking: PHPStan

```bash
composer require --dev phpstan/phpstan
```

**phpstan.neon:**

```neon
parameters:
    level: 8
    paths:
        - src
    excludePaths:
        - tests
```

---

## Formatting: PHP-CS-Fixer

```bash
composer require --dev friendsofphp/php-cs-fixer
```

**.php-cs-fixer.php:**

```php
<?php
return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
        'array_syntax' => ['syntax' => 'short'],
        'no_unused_imports' => true,
    ])
    ->setFinder(PhpCsFixer\Finder::create()->in(__DIR__.'/src'));
```

---

## Git Hooks: GrumPHP

```bash
composer require --dev phpro/grumphp
```

**grumphp.yml:**

```yaml
grumphp:
    tasks:
        phpstan: ~
        phpcsfixer: ~
```

---

## Coverage: PCOV

```bash
composer require --dev pcov/clobber
```

**phpunit.xml:**

```xml
<phpunit>
    <coverage>
        <report>
            <clover outputFile="coverage.xml"/>
            <html outputDirectory="coverage-html"/>
        </report>
    </coverage>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
</phpunit>
```

**Run with threshold:**

```bash
XDEBUG_MODE=coverage ./vendor/bin/phpunit --coverage-text --min=80
```
