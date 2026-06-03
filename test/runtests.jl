using Test
using MorkServer

@testset "MorkServer" begin
    # Unit tests — no server; exercise a layer directly.
    @testset "unit/resource_store" begin
        include(joinpath(@__DIR__, "unit", "resource_store.jl"))
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
        "metta_thread_suspend_e2e",
    ]
        @testset "$f" begin
            include(joinpath(@__DIR__, "integration", "$f.jl"))
        end
    end
end
