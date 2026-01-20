# Ruby

Quality tooling for Ruby projects.

---

## Linting + Formatting: RuboCop

```bash
gem install rubocop
# or add to Gemfile: gem 'rubocop', require: false, group: :development
```

**.rubocop.yml:**

```yaml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2

Style/StringLiterals:
  EnforcedStyle: double_quotes

Layout/LineLength:
  Max: 120
```

---

## Git Hooks: Overcommit

```bash
gem install overcommit
overcommit --install
```

**.overcommit.yml:**

```yaml
PreCommit:
  RuboCop:
    enabled: true
    command: ['rubocop', '--auto-correct']
```

---

## Type Checking: Sorbet (optional)

```bash
gem install sorbet sorbet-runtime
srb init
```

---

## Coverage: SimpleCov

```bash
gem install simplecov
# or add to Gemfile: gem 'simplecov', require: false, group: :test
```

**spec/spec_helper.rb:**

```ruby
require 'simplecov'
SimpleCov.start do
  minimum_coverage 80
  minimum_coverage_by_file 70
  add_filter '/spec/'
  add_filter '/test/'
end
```
