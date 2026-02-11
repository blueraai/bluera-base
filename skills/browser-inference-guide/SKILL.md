---
name: browser-inference-guide
description: >-
  Use when working on in-browser ML/LLM inference, WebGPU/WASM/WebNN backends,
  vendor built-in AI APIs (Chrome Prompt API, Summarizer, Edge Prompt API),
  model caching (OPFS/Cache API), or cross-origin isolation (COOP/COEP).
  Provides expert guidance, reviews implementations, and audits against best practices.
argument-hint: "<question or 'review' or 'audit'>"
allowed-tools: [Read, Glob, Grep, Task, WebSearch, WebFetch, AskUserQuestion]
---

# Browser Inference Guide

Expert guidance for client-side ML/LLM inference in the browser.

## When This Skill Applies

Auto-invoke when:

- Questions about WebGPU, WebNN, or WASM-based inference
- Working on files involving ORT-Web, Transformers.js, WebLLM, or wllama
- Browser capability detection or backend routing logic
- Model storage strategy (Cache API, OPFS, IndexedDB)
- COOP/COEP or cross-origin isolation configuration
- Vendor built-in AI APIs (Chrome Prompt API, Summarizer, Edge Prompt API)
- Safari/iOS compatibility or safe-mode implementation

## Workflow

### 1. Detect Mode

Parse argument to determine mode:

- **`review`** — Review an implementation against spec requirements
- **`audit`** or **`audit [path] [focus]`** — Comprehensive audit against checklist
- **Question text** — Answer using expert knowledge
- **No argument** — Use AskUserQuestion with options:
  - "Ask a question" — Question mode
  - "Review my implementation" — Review mode
  - "Audit against checklist" — Audit mode

### 2. Load Local Context

Read the following files if they exist (skip gracefully if missing):

1. `.ignore/inference-in-the-browser-spec_2026-01-10.md` — local engineering spec
2. `skills/browser-inference-guide/references/authoritative-urls.md` — curated URL list

If the spec file is missing, Glob for `*inference*spec*` in `.ignore/`. If still not found, note "no local spec available" and proceed with references + web only.

**Rule:** Always load local context before any WebSearch. Use web only to verify current browser support or fill gaps not in the spec.

### 3. For Questions

Spawn the agent:

```yaml
task:
  subagent_type: general-purpose
  prompt: |
    User question: $ARGUMENTS

    ## Context
    [Insert local spec content if available, otherwise note "no local spec"]
    [Insert authoritative-urls.md content]

    ## Instructions
    1. Answer from the local spec first (cite section numbers)
    2. Use WebSearch only to verify current browser support status
    3. Cite all sources (spec sections, URLs, file paths)
    4. If the spec doesn't cover the topic, use authoritative URLs + web search

    ## Output format
    Answer the question directly, then include a "Sources" section with citations.
```

### 4. For Review Mode

Spawn the agent:

```yaml
task:
  subagent_type: general-purpose
  prompt: |
    Review the user's browser inference implementation.

    ## Context
    [Insert local spec content if available]
    [Insert authoritative-urls.md content]

    ## Review against spec requirements
    - FR1-FR5 (Functional): unified API, backend routing, model registry, offline, degradation
    - PR1-PR4 (Performance): off-thread, I/O binding, concurrency, caching
    - RR1-RR2 (Reliability): Safari safe-mode, deterministic errors
    - SR1-SR2 (Security): COOP/COEP, CORS implications

    ## Instructions
    1. Read the user's code (Glob for relevant files, Read key ones)
    2. Compare against each requirement category
    3. Use WebSearch to verify current browser support claims

    ## Output format
    ## Review: [project/feature name]
    ### Strengths
    ### Issues (by requirement category)
    ### Recommendations (prioritized)
    ### Sources
```

### 5. For Audit Mode

Parse arguments: first arg starting with `/` or `.` or containing `/` is a path; remaining args are focus instructions.

Spawn the agent:

```yaml
task:
  subagent_type: general-purpose
  prompt: |
    Perform a comprehensive browser inference audit.

    **Target**: $PATH (or current directory)
    **Focus**: $INSTRUCTIONS (or "full audit")

    ## References
    [Insert local spec content if available]
    Read the checklist: skills/browser-inference-guide/references/audit-checklist.md

    ## Instructions
    1. For each applicable checklist section, check current state
    2. Compare against best practices from spec + checklist
    3. Note issues with severity (Critical/Warning/Suggestion)
    4. Use WebSearch to verify browser support claims are current

    ## Output format
    ## Audit Report: [project name]
    ### Summary
    - Critical: N | Warnings: N | Suggestions: N
    ### Findings
    [Grouped by checklist section, only sections with findings]
    ### Recommendations
    [Prioritized fixes]
    ### Sources
```

## Quick Reference

### Backend Selection Priority

| Priority | Backend | Condition |
|----------|---------|-----------|
| 1 | Vendor built-in API | Task is summarize/translate/detect + API exists |
| 2 | WebGPU (ONNX/MLC) | `navigator.gpu` available + healthy |
| 3 | WASM SIMD | SIMD supported |
| 4 | WASM SIMD + threads | `crossOriginIsolated` + platform-safe |
| 5 | `ERR_NO_BACKEND` | None available |

### Runtime Comparison

| Runtime | Format | Best For | Notes |
|---------|--------|----------|-------|
| ORT-Web (WebGPU EP) | ONNX | Embeddings, classification, vision | Stable session API, I/O binding |
| ORT-Web (WASM EP) | ONNX | CPU fallback | Universal, SIMD + optional threads |
| Transformers.js v3 | ONNX | Pipeline API convenience | Uses ORT-Web under the hood |
| WebLLM (MLC) | MLC | Chat-style LLMs | OpenAI-compatible interface |
| wllama | GGUF | llama.cpp models | WASM-only, 2GB model ceiling, split support |

### Storage Hierarchy

| Storage | Use For | Limits |
|---------|---------|--------|
| Cache API | HTTP-fetched model artifacts | Quota-managed, SW integration |
| OPFS | Large binary shards | Fast I/O, 3-4x faster than IDB |
| IndexedDB | Metadata, checksums, small assets | Quota issues with large blobs |

### COOP/COEP Headers

| Header | Value | Required For |
|--------|-------|-------------|
| `Cross-Origin-Opener-Policy` | `same-origin` | WASM threads, SharedArrayBuffer |
| `Cross-Origin-Embedder-Policy` | `require-corp` | WASM threads, SharedArrayBuffer |

**Warning:** Cross-origin isolation breaks embedded third-party resources without CORP/CORS headers.

### Safari/iOS Safe-Mode

| Rule | Rationale |
|------|-----------|
| Prefer smaller quantized variants | Memory pressure causes crashes |
| Throttle to single in-flight generation | Concurrent GPU work destabilizes |
| Disable large KV caches | Memory allocation failures |
| Consider WASM over WebGPU when health degrades | WebGPU device-lost is common |
| Disable threaded WASM on iOS | COOP/COEP can cause hangs |

## Related Skills

| Skill | Use For |
|-------|---------|
| `/bluera-base:claude-code-guide` | Claude Code plugin development questions |

## Constraints

- Always load local spec + authoritative URLs before web lookup
- Cite sources (spec section numbers, URLs, file paths)
- Don't assume API availability — always probe/verify current status
- WebSearch for current browser support verification only, not architecture guidance
- Spawn general-purpose agents for detailed work in all modes
