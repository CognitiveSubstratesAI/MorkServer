# MorkServer.jl — HTTP server layer on top of MORK kernel.
#
# Ports `mork/server/` from upstream MORK. Provides:
#
#   - `MorkServer` struct + `serve!` / `serve_background!` — HTTP/1.1 server
#   - `ResourceStore` / `ResourceHandle` — content-hashed temp files for streaming
#   - `ServerSpace` + `StatusMap` — path-level permission + status tracking
#   - `Commands` table — dispatches GET/POST to command handlers
#     (busywait, clear, copy, count, explore, export, import, upload, transform,
#      status, stop, metta_thread, metta_thread_suspend)
#
# Lives in its own package (separated from MORK kernel 2026-05-30) so kernel
# consumers (Core, MorkSupercompiler, etc.) don't pull HTTP + JSON3 transitive
# deps. Upstream Rust analog: kernel/ crate vs server/ crate split.
#
# Architecture decision recorded: PRIMUS kept this split as two separate Julia
# packages (MORK + MorkServer) rather than upstream's branch-based split
# (main + server branch). Branches-as-feature-flags is non-idiomatic in Julia;
# two packages is the standard pattern.
#
# NOTE on naming: this module is named `MorkServer`, and so is the HTTP-server
# struct defined inside (`mutable struct MorkServer` in Server.jl, mirroring
# upstream Rust's MorkService). Julia handles the name overlap, but a
# `"""..."""` docstring at the top of either file gets attached to the struct
# rather than the module — Julia then fails with
#   MethodError doc!(::Type{MorkServer.MorkServer}, ...)
# because it tries to use the struct type as if it were a Module. Both this
# file and Server.jl use `#` comment blocks instead of `"""..."""` for that
# reason. The content is identical; only the binding is avoided.

module MorkServer

using HTTP
using JSON3
using MORK
using PathMap

# Pull in the MORK-internal kernel symbols the server layer uses but that
# aren't part of MORK's public export list. Explicit `using MORK: ...` so
# the dependency is visible at the top of this module rather than implicit
# via bare-name resolution that worked when these files lived inside MORK.
using MORK: Space, ACT_PATH,
    sexpr_to_expr, expr_serialize,
    _derive_prefix,
    space_add_sexpr!, space_dump_sexpr,
    space_load_csv!, space_load_json!,
    space_metta_calculus_at!,
    space_transform_multi_multi!,
    space_token_bfs,
    space_interpret!, space_backup_paths,
    space_val_count,
    asource_new, source_factor, ExecError
using PathMap: read_zipper_at_path, set_val_at!

# ── Server layer source files (in dependency order — same as mork/server/) ──
include("ResourceStore.jl")
include("ServerSpace.jl")
include("Commands.jl")
include("Server.jl")

# Re-export the same surface server consumers used to see at MORK.*
# (Mirrors what MORK.jl previously exported from these files.)
# ResourceStore
export ResourceStore,
    ResourceHandle, rh_path, rh_finalize!,
    rs_new_resource, rs_reset!, rs_purge_before!
# ServerSpace + StatusMap
export ServerSpace, StatusMap, StatusRecord, StatusKind,
    ReadPermission, WritePermission,
    PATH_CLEAR, PATH_READ_ONLY, PATH_READ_ONLY_TEMPORARY,
    PATH_FORBIDDEN, PATH_FORBIDDEN_TEMPORARY, SERVER_SHUTDOWN,
    STATUS_COUNT_RESULT, STATUS_FETCH_ERROR, STATUS_PARSE_ERROR, STATUS_EXEC_ERROR,
    status_to_json, status_blocks_writer, status_blocks_reader,
    sm_get_status, sm_try_set_user_status!, sm_clear_user_status!,
    sm_get_read_permission, sm_release_read!,
    sm_get_write_permission, sm_release_write!,
    sm_add_stream!, sm_shutdown!,
    ss_get_status, ss_set_status!, ss_new_reader, ss_new_writer,
    ss_release_reader!, ss_release_writer!,
    ss_new_multiple, ss_new_writer_retry
# Commands
export WorkResult, DataFormat, COMMAND_TABLE,
    FMT_METTA, FMT_CSV, FMT_JSON, FMT_JSONL, FMT_RAW, FMT_PATHS,
    work_ok, work_error, work_stream, dataformat_from_str,
    cmd_busywait, cmd_clear, cmd_copy, cmd_count, cmd_explore,
    cmd_export, cmd_import, cmd_upload, cmd_transform,
    cmd_status, cmd_stop, cmd_metta_thread, cmd_metta_thread_suspend
# Server
# NOTE: `MorkServer` (the struct) shares its name with this module.
# Julia handles this — within the module, `MorkServer` refers to the struct;
# from outside, `MorkServer.MorkServer(...)` constructs the struct.
export MorkServer, serve!, serve_background!

end # module MorkServer
