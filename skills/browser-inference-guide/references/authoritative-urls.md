# Authoritative URLs — Browser Inference

Curated reference list for in-browser ML/LLM inference. Organized by topic.

## W3C / Standards

- [WebGPU Specification](https://gpuweb.github.io/gpuweb/) — W3C WebGPU API spec
- [WebNN API (W3C TR)](https://www.w3.org/TR/webnn/) — Web Neural Network API specification
- [WebNN Publication History](https://www.w3.org/standards/history/webnn/) — Includes 2026-01-09 CRD
- [WebNN Explainer](https://github.com/webmachinelearning/webnn/blob/main/explainer.md) — WebNN motivation and design

## Browser Implementation Status

- [GPUWeb Implementation Status](https://github.com/gpuweb/gpuweb/wiki/Implementation-Status) — Per-browser WebGPU support status
- [Can I Use: WebGPU](https://caniuse.com/?search=webgpu) — Browser compatibility table
- [Can I Use: WebNN](https://caniuse.com/?search=webnn) — Browser compatibility (experimental/flags)
- [Web Platform Status: WebNN](https://webstatus.dev/features/webnn) — Cross-browser implementation tracking
- [WebGPU Supported in Major Browsers](https://web.dev/blog/webgpu-supported-major-browsers) — web.dev announcement and status
- [Chrome WebGPU Overview](https://developer.chrome.com/docs/web-platform/webgpu/overview) — Chrome team WebGPU docs

## ONNX Runtime Web

- [ORT WebGPU EP](https://onnxruntime.ai/docs/tutorials/web/ep-webgpu.html) — WebGPU execution provider tutorial
- [ORT WASM EP (Env Flags & Session Options)](https://onnxruntime.ai/docs/tutorials/web/env-flags-and-session-options.html) — WASM config including numThreads
- [ORT Performance Diagnosis](https://onnxruntime.ai/docs/tutorials/web/performance-diagnosis.html) — Profiling and diagnosis for web
- [ORT I/O Binding](https://onnxruntime.ai/docs/performance/tune-performance/iobinding.html) — Minimize CPU↔GPU copies
- [ORT Web Build Docs](https://onnxruntime.ai/docs/build/web.html) — Custom builds with SIMD/threads flags
- [ORT WebNN EP](https://onnxruntime.ai/docs/tutorials/web/ep-webnn.html) — WebNN execution provider (behind flags)
- [ORT WASM Flags API](https://onnxruntime.ai/docs/api/js/interfaces/Env.WebAssemblyFlags.html) — JS API for WASM env flags
- [ORT Web Tutorial Index](https://onnxruntime.ai/docs/tutorials/web/) — All ORT-Web tutorials

## Transformers.js

- [Transformers.js WebGPU Guide](https://huggingface.co/docs/transformers.js/en/guides/webgpu) — Enable GPU via `device: 'webgpu'`
- [Transformers.js v3 Blog](https://huggingface.co/blog/transformersjs-v3) — v3 release with WebGPU support
- [Transformers.js GitHub](https://github.com/huggingface/transformers.js) — Source and examples

## WebLLM (MLC)

- [WebLLM Basic Usage](https://webllm.mlc.ai/docs/user/basic_usage.html) — OpenAI-style chat interface
- [WebLLM GitHub](https://github.com/mlc-ai/web-llm) — Source, model catalog, examples

## wllama

- [wllama GitHub](https://github.com/ngxson/wllama) — WebAssembly binding for llama.cpp
- [wllama npm](https://www.npmjs.com/package/@wllama/wllama) — Package with version history
- [wllama Docs](http://github.ngxson.com/wllama/docs/) — API documentation

## Chrome Built-in AI

- [Prompt API](https://developer.chrome.com/docs/ai/prompt-api) — Chrome extensions, Gemini Nano, system requirements
- [Summarizer API](https://developer.chrome.com/docs/ai/summarizer-api) — Available from Chrome 138 stable
- [Built-in APIs Overview](https://developer.chrome.com/docs/ai/built-in-apis) — Summarizer, Language Detector, Translator
- [Get Started with Built-in AI](https://developer.chrome.com/docs/ai/get-started) — Setup and first use
- [Cache Models Guide](https://developer.chrome.com/docs/ai/cache-models) — Caching guidance for built-in models
- [MDN: Summarizer API](https://developer.mozilla.org/en-US/docs/Web/API/Summarizer_API) — Web standard reference

## Edge Built-in AI

- [Edge Prompt API](https://learn.microsoft.com/en-us/microsoft-edge/web-platform/prompt-api) — Phi-4-mini, system requirements
- [Edge Writing Assistance APIs](https://learn.microsoft.com/en-us/microsoft-edge/web-platform/writing-assistance-apis) — Summarizer, Writer, Rewriter
- [Edge AI Blog Post](https://blogs.windows.com/msedgedev/2025/05/19/introducing-the-prompt-and-writing-assistance-apis/) — Launch announcement
- [WebNN Overview (Microsoft)](https://learn.microsoft.com/en-us/windows/ai/directml/webnn-overview) — DirectML/NPU context

## Storage

- [OPFS (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system) — Origin Private File System API
- [OPFS (web.dev)](https://web.dev/articles/origin-private-file-system) — Usage guide and performance
- [Cache API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Cache) — Cache interface for request/response pairs
- [File System API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API) — File System Access overview
- [IndexedDB (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API) — Client-side structured storage

## Cross-Origin Isolation

- [COOP Header (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cross-Origin-Opener-Policy) — Cross-Origin-Opener-Policy
- [COEP Header (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cross-Origin-Embedder-Policy) — Cross-Origin-Embedder-Policy
- [COOP/COEP Guide (web.dev)](https://web.dev/articles/coop-coep) — Making your site cross-origin isolated
- [Cross-Origin Isolation Guide (web.dev)](https://web.dev/articles/cross-origin-isolation-guide) — Step-by-step enablement
- [SharedArrayBuffer (MDN)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer) — Requires cross-origin isolation

## Known Issues

Open issues from the ecosystem. Check status before relying on workarounds.

- [ORT Safari/WebKit JSEP Crashes (#26827)](https://github.com/microsoft/onnxruntime/issues/26827) — High CPU/memory, crashes on iOS
- [ImGui Safari 26 Device-Lost (#9103)](https://github.com/ocornut/imgui/issues/9103) — WebGPU device lost in Safari 26
- [WebLLM Safari Scrambled Outputs (#386)](https://github.com/mlc-ai/web-llm/issues/386) — Safari TP memory/output issues
- [Transformers.js iOS Memory (#1242)](https://github.com/huggingface/transformers.js/issues/1242) — iOS/macOS memory growth/crashes
- [ORT iOS COOP/COEP Hanging (#11679)](https://github.com/microsoft/onnxruntime/issues/11679) — Cross-origin isolation hangs on iPad
- [WebLLM IDB Quota Failures (#374)](https://github.com/mlc-ai/web-llm/issues/374) — IndexedDB cache failures in Chrome
- [GitHub Pages COOP/COEP (#13309)](https://github.com/orgs/community/discussions/13309) — Can't set headers on GitHub Pages

## Maintaining This List

- Spot-check URL health: `rg -o 'https?://[^)]+' references/authoritative-urls.md | head -10 | xargs -I{} curl -sL -o /dev/null -w "%{http_code} {}\n" {}`
- Add new URLs when ecosystem changes (new runtimes, new browser APIs)
- Mark deprecated URLs with ~~strikethrough~~ and date removed
- Move resolved GitHub issues to a "Resolved Issues" subsection
