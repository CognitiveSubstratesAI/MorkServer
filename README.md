# MorkServer.jl

HTTP server layer for [MORK](https://github.com/sivaji1012/MORK).

Ports the upstream `mork/server/` Rust crate. Provides:

- `MorkServer` + `serve!` / `serve_background!` — HTTP/1.1 server (HTTP.jl)
- `ResourceStore` — content-hashed temp files for streaming uploads/downloads
- `ServerSpace` + `StatusMap` — path-level read/write permission tracking
- `COMMAND_TABLE` — GET/POST dispatch for: `busywait`, `clear`, `copy`, `count`,
  `explore`, `export`, `import`, `upload`, `transform`, `status`, `stop`,
  `metta_thread`, `metta_thread_suspend`

## Why split from MORK

MORK kernel consumers (the substrate library) shouldn't pay for HTTP +
JSON3 deps they don't use. This split mirrors upstream's Rust workspace
(`kernel/` crate vs `server/` crate). PRIMUS chose two Julia packages
rather than upstream's branch-based split because branches-as-feature-flags
is non-idiomatic in Julia.

## Install

This package depends on `MORK`. Once both are registered:

```julia
pkg> add MorkServer
```

For local development against unregistered packages:

```julia
pkg> activate .
pkg> develop ../MORK ../PathMap
pkg> instantiate
```

## Usage

```julia
using MorkServer

server = MorkServer.MorkServer(port=8000)
serve_background!(server)
# ... HTTP calls to http://127.0.0.1:8000 ...
# server stops when /stop endpoint is hit, or via SIGTERM
```

Environment variables (mirrors upstream):

| Var | Default | Description |
|---|---|---|
| `MORK_SERVER_ADDR` | `127.0.0.1` | Bind address |
| `MORK_SERVER_PORT` | `8000` | TCP port |
| `MORK_SERVER_DIR` | `/tmp/mork_server_files` | Resource/ACT file directory |

## Tests

Integration tests spin up a real server per test:

```julia
pkg> test
```

Tests included: `metta_thread_basic`, `metta_thread_self_ref`, `server_branch`,
`server_e2e`, `server_http`, `copy_e2e`, `explore_e2e`, `import_e2e`,
`metta_thread_e2e`, `metta_thread_suspend_e2e`.

## License

Same as MORK upstream (see https://github.com/trueagi-io/MORK).
