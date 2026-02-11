# Browser Inference Audit Checklist

Comprehensive checklist for auditing in-browser ML/LLM inference implementations.

**Reference Documents:**

- [Local Engineering Spec](../../../.ignore/inference-in-the-browser-spec_2026-01-10.md) (if available in project)
- [Authoritative URLs](authoritative-urls.md)

## 1. Capability Detection

> Reference: Spec section 4.2.2 (CapabilityRouter), section 7.2 (PlatformSnapshot)

- [ ] Probes WebGPU via `navigator.gpu` and requests adapter
- [ ] Detects WASM SIMD support
- [ ] Checks `crossOriginIsolated` before enabling WASM threads
- [ ] Detects vendor built-in APIs (`LanguageModel`, `Summarizer`, `Translator`, `LanguageDetector`)
- [ ] Reads `navigator.deviceMemory` and `navigator.hardwareConcurrency` when available
- [ ] Produces a structured `PlatformSnapshot` (or equivalent) for routing decisions
- [ ] Detection is non-blocking and handles missing APIs gracefully

## 2. Backend Routing

> Reference: Spec section 8 (Backend Selection Policy)

- [ ] Router follows priority order: vendor built-in → WebGPU → WASM SIMD → WASM threads → error
- [ ] Health-based downgrades implemented (device-lost count, OOM, init timeout → downgrade one tier)
- [ ] Cooldown persisted (IDB or equivalent) after repeated failures
- [ ] No hard dependency on vendor built-in APIs — always falls through to BYOM
- [ ] Produces `ERR_NO_BACKEND` with structured diagnostics when all backends fail
- [ ] User preferences respected (`preferLocal`, `preferBuiltIn`, `preferOffline`)
- [ ] Task-based routing: summarize/translate/detect → built-in API when available

## 3. WebGPU Implementation

> Reference: Spec sections 5.2 (WebGPU BYOM), 10.1 (Safari risks)

- [ ] Handles `device-lost` event: recreates device/session once, then falls back
- [ ] Memory guardrails: denies loading models above configured threshold
- [ ] Inference runs in a Web Worker (off main thread)
- [ ] I/O binding used to keep tensors on-device (avoids CPU↔GPU copies)

### Safari/iOS Safe-Mode

- [ ] Detects Safari/WebKit family (UA or feature detection)
- [ ] Prefers smaller quantized variants (Q4/Q5 over fp16)
- [ ] Throttles to single in-flight generation
- [ ] Disables optional high-memory features (large KV caches)
- [ ] Considers WASM fallback when WebGPU health degrades on Safari

## 4. WASM Implementation

> Reference: Spec sections 5.3 (WebAssembly), 10.2 (thread constraints)

- [ ] Configurable `numThreads` (respects ORT default: half cores, capped)
- [ ] COOP/COEP gating: does not attempt threaded WASM unless `crossOriginIsolated === true`
- [ ] iOS/Safari policy: prefers single-threaded WASM (known hanging issues with COOP/COEP)
- [ ] Init timeout controls exposed (ORT env flags)
- [ ] Handles 2GB ArrayBuffer ceiling for wllama/GGUF models (uses model splitting)
- [ ] SIMD-only path works without cross-origin isolation

## 5. Vendor API Integration

> Reference: Spec sections 5.1 (Vendor Built-in APIs), 3.1 FR2

- [ ] Never required — always falls back to BYOM if unavailable
- [ ] Platform/disk gating handled (Chrome requires large free disk, desktop-only for Prompt API)
- [ ] Task routing: summarize/translate/language-detect → built-in when Chrome 138+ detected
- [ ] Prompt API used opportunistically for extraction, classification, rewriting
- [ ] Edge Prompt API (Phi-4-mini) supported where available
- [ ] Graceful handling when model download is pending or fails

## 6. Model Storage & Caching

> Reference: Spec section 6 (Storage, caching, artifact delivery)

### Storage Strategy

- [ ] Cache API used for HTTP-fetched model artifacts (primary)
- [ ] OPFS used for large binary shards where supported
- [ ] IndexedDB used for metadata (manifest, checksums, timestamps) only
- [ ] Service worker pre-caches UI + router code, lazy-fetches model artifacts

### Artifact Management

- [ ] JSON manifest per model variant: id, format, quant, totalBytes, shards (URL + bytes + sha256)
- [ ] sha256 integrity verification on cached shards
- [ ] Corrupted shard triggers re-download
- [ ] Large weights sharded for parallel download and retry
- [ ] Progress events exposed during download
- [ ] LRU metadata recorded for eviction decisions

### Quota Handling

- [ ] Provides UX for "insufficient storage" condition
- [ ] Avoids IDB for very large binaries (uses OPFS or Cache API)
- [ ] Validates cached sizes and handles quota eviction gracefully

## 7. Unified API Surface

> Reference: Spec section 7 (Unified API surface)

- [ ] `chat.completions` endpoint with OpenAI-style request/response shapes
- [ ] Streaming support via `AsyncIterable<Chunk>` (delta, usage, done)
- [ ] `embeddings` endpoint with batch input support
- [ ] `summarize` / `translate` endpoints that map to built-in APIs when present
- [ ] Structured error codes and diagnostics (not generic error messages)
- [ ] Response includes `backend` field indicating which backend served the request

## 8. Security & Deployment

> Reference: Spec sections 3.4 (Security requirements), 6.3 (Artifact packaging)

- [ ] COOP/COEP headers set correctly when WASM threads are used
- [ ] CORS/CORP implications documented for third-party resources
- [ ] Model files served with correct MIME types and CORS headers
- [ ] No secrets or API keys in model manifests or client code
- [ ] Self-hosting considered for critical assets (avoids CORP issues under cross-origin isolation)

## 9. Performance

> Reference: Spec section 3.2 (Performance requirements)

- [ ] Inference runs off main thread (Web Worker) — PR1
- [ ] GPU tensors stay on-device (I/O binding, no unnecessary CPU↔GPU copies) — PR2
- [ ] Configurable concurrency limits (parallel sessions capped) — PR3
- [ ] Cancellation/abort support (AbortController or equivalent) — PR3
- [ ] Caching avoids repeated multi-GB fetches, supports resume/verification — PR4
- [ ] Token throughput measurable (tokens/s logged for observability)

---

## Severity Levels

When reporting findings, use these severity levels:

| Severity | Description |
|----------|-------------|
| **Critical** | Security risk, data loss potential, crashes on major platforms, or missing core functionality |
| **Warning** | Best practice violation, degraded performance, Safari/iOS incompatibility |
| **Suggestion** | Optimization opportunity, improved UX, observability enhancement |

---

## Updating This Checklist

This checklist should be updated when:

- New browser APIs ship (e.g., WebNN becomes widely available without flags)
- New runtimes emerge or existing ones change significantly
- Known issues are resolved or new platform-specific bugs are discovered
- The local engineering spec is revised

Use `/bluera-base:browser-inference-guide` to research latest recommendations before updating.
