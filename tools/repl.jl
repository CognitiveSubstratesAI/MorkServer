#!/usr/bin/env julia
# tools/repl.jl — development REPL
#
# Interactive:
#   julia --project=. -i tools/repl.jl
#
# Scripted:
#   printf 'include("test/runtests.jl")\n' | julia --project=. tools/repl.jl
#   printf 't()\n' | julia --project=. tools/repl.jl

try
    using Revise
catch
end

using MorkServer

# ── Shortcuts ─────────────────────────────────────────────────────────────────

t(path = joinpath(@__DIR__, "..", "test", "runtests.jl")) = include(path)

# Start server in background for interactive testing
function start_server(port::Int = 8000)
    s = MorkServer.MorkServer(port = port)
    @async serve!(s)
    sleep(1)
    println("MorkServer on :$port")
    s
end

if isinteractive()
    println("MorkServer v0.1.0 loaded.")
    println("  t()                    — run full test suite")
    println("  start_server([port])   — start HTTP server for manual testing")
end
