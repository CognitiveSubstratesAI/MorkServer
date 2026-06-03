# MorkServer.jl

The HTTP server layer for the [MORK](https://github.com/CognitiveSubstratesAI/MORK)
metagraph engine — a Julia port of the upstream `mork/server/` Rust crate, hardened
by a Rust→Julia porting audit (Drop-parity resource cleanup, prefix-aware permission
conflicts, O(1) by-reference `copy`).

It exposes an HTTP/1.1 API over a shared MORK `Space`:

- **Commands** — `upload`, `import`, `count`, `explore`, `export`, `copy`,
  `transform`, `clear`, `metta_thread` (+ suspend), `status` / `status_stream`, `stop`.
- **Concurrency** — per-path read/write permissions with prefix-aware conflict
  detection (mirrors upstream `ZipperTracker`); status streams via SSE.
- **Resource store** — versioned, content-addressed import cache with Drop-parity
  cleanup of abandoned downloads.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/CognitiveSubstratesAI/MorkServer")
```

## Quickstart

```julia
using MorkServer
serve!(MorkServer.MorkServer(port = 8000))   # blocks; serves the command API on :8000
```

Then, e.g.:

```bash
curl -s -X POST 'http://127.0.0.1:8000/upload/%24x/%24x?format=metta' \
  --data-binary $'(rel a b)\n(rel b c)\n'
curl -s -X POST 'http://127.0.0.1:8000/count/%24x'     # → ACK; result via /status
```
