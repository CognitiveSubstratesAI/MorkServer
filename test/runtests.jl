using Test
using MorkServer
# Aqua is test-only [extras]: present under Pkg.test/CI but NOT in a plain
# `julia --project=. test/runtests.jl` run (no sandbox). Load optionally.
const _HAS_AQUA = try; @eval using Aqua; true; catch; false; end

@testset "MorkServer" begin
    if _HAS_AQUA
        @testset "Aqua quality" begin
            # deps_compat check_extras=false: the Test/Aqua extras are dev-only; runtime
            # deps (HTTP, JSON3, MORK, PathMap) carry [compat] (MORK/PathMap dev-linked
            # via [sources], so deps_compat skips them).
            Aqua.test_all(MorkServer; deps_compat=(check_extras=false,))
        end
    else
        @info "Aqua not loadable (plain julia --project=.) — runs under Pkg.test/CI"
    end

    # Unit tests — no server; exercise a layer directly.
    @testset "unit/resource_store" begin
        include(joinpath(@__DIR__, "unit", "resource_store.jl"))
    end
    @testset "unit/server_space" begin
        include(joinpath(@__DIR__, "unit", "server_space.jl"))
    end

    # Integration tests — spin up a real HTTP server per test file.
    # These were moved from packages/MORK/test/integration/ on 2026-05-30
    # when MORK kernel and server were split into separate packages.
    for f in [
        "metta_thread_basic",
        "metta_thread_self_ref",
        "server_branch",
        "server_e2e",
        "server_http",
        "copy_e2e",
        "explore_e2e",
        "import_e2e",
        "metta_thread_e2e",
        "metta_thread_suspend_e2e"
    ]
        @testset "$f" begin
            include(joinpath(@__DIR__, "integration", "$f.jl"))
        end
    end
end
