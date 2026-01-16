# README Structure Template

Recommended section order and content for well-structured README files.

## Minimal README (Quick Start)

```markdown
# Project Name

> One-line description.

## Installation

\`\`\`bash
npm install project-name
\`\`\`

## Usage

\`\`\`javascript
import { thing } from 'project-name';
thing.doStuff();
\`\`\`

## License

MIT
```

## Standard README

```markdown
# Project Name

[![CI](badge)](link) [![npm](badge)](link) [![License](badge)](link)

> Concise description of what this project does and why it's useful.

## Installation

\`\`\`bash
npm install project-name
\`\`\`

## Quick Start

\`\`\`javascript
import { Feature } from 'project-name';

const result = Feature.doThing();
console.log(result);
\`\`\`

## Features

| Feature | Description |
|---------|-------------|
| Feature 1 | What it does |
| Feature 2 | What it does |
| Feature 3 | What it does |

## API

### `functionName(options)`

Description of the function.

**Parameters:**
- `options.param1` (string) - Description
- `options.param2` (number, optional) - Description. Default: `10`

**Returns:** Description of return value.

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT - See [LICENSE](./LICENSE)
```

## Comprehensive README

```markdown
# Project Name

[![CI](badge)](link) [![npm](badge)](link) [![Downloads](badge)](link) [![License](badge)](link)

> Compelling one-line description of the project.

**Key benefit 1** | **Key benefit 2** | **Key benefit 3**

<details>
<summary>Table of Contents</summary>

- [Why Project Name?](#why-project-name)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Features](#features)
- [Architecture](#architecture)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

</details>

---

## Why Project Name?

Brief motivation. What problem does this solve? Why should someone use it?

| Without Project | With Project |
|-----------------|--------------|
| Problem 1 | Solution 1 |
| Problem 2 | Solution 2 |

---

## Installation

<details>
<summary><b>npm (recommended)</b></summary>

\`\`\`bash
npm install project-name
\`\`\`

</details>

<details>
<summary><b>yarn</b></summary>

\`\`\`bash
yarn add project-name
\`\`\`

</details>

<details>
<summary><b>From source</b></summary>

\`\`\`bash
git clone https://github.com/org/project-name
cd project-name
npm install
npm run build
\`\`\`

</details>

---

## Quick Start

\`\`\`javascript
import { Feature } from 'project-name';

// Basic usage
const result = await Feature.process(input);
console.log(result);
\`\`\`

---

## Features

| Feature | Description | Status |
|---------|-------------|--------|
| Feature 1 | What it does | Stable |
| Feature 2 | What it does | Stable |
| Feature 3 | What it does | Beta |

---

## Architecture

\`\`\`mermaid
flowchart LR
    A[Input] --> B[Processor]
    B --> C[Output]
\`\`\`

---

## API Reference

### `mainFunction(options)`

Primary function description.

\`\`\`typescript
mainFunction({
  input: string,
  options?: Options
}): Promise<Result>
\`\`\`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| input | string | Yes | Input description |
| options | Options | No | See Options below |

**Returns:** `Promise<Result>` - Description

---

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| option1 | string | `"default"` | Description |
| option2 | number | `10` | Description |
| option3 | boolean | `false` | Description |

---

## Troubleshooting

<details>
<summary><b>Error: Something went wrong</b></summary>

**Cause:** Description of why this happens.

**Solution:**
1. Step 1
2. Step 2

</details>

<details>
<summary><b>Issue: Performance is slow</b></summary>

**Cause:** Description.

**Solution:** Description.

</details>

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests
4. Submit a pull request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

---

## License

MIT - See [LICENSE](./LICENSE)
```

## Section Guidelines

### Title + Badges

- Project name as h1
- 3-6 relevant badges immediately after
- One-line tagline as blockquote or bold

### Table of Contents

- Use collapsible for 5+ sections
- Link to all major sections
- Update when adding sections

### Features

- Use table if features have multiple attributes
- Use list if just names/descriptions
- Include status (stable/beta/planned) if relevant

### Installation

- Show primary method prominently
- Collapse alternative methods
- Include prerequisites if any

### API/Configuration

- Use tables for options/parameters
- Include types and defaults
- Show examples for complex options

### Troubleshooting

- Use collapsible for each issue
- Include cause and solution
- Add as users report problems

### Contributing

- Keep brief in README
- Link to CONTRIBUTING.md for details
- Include basic steps inline
