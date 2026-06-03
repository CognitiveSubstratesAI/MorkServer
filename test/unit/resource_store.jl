using Test
using MorkServer
using MorkServer: ResourceStore, ResourceHandle, rs_new_resource, rh_path,
                  rh_finalize!, rs_reset!, rs_purge_before!

@testset "ResourceStore (unit)" begin
    # R-4 (Drop parity): an abandoned, un-finalized handle must remove its
    # in-progress file. `finalize(h)` runs registered finalizers synchronously, so
    # this is deterministic. Pre-fix (no finalizer registered) it FAILS — the file
    # lingers; post-fix the registered `close` finalizer removes it.
    @testset "finalizer cleans up abandoned in-progress file (R-4)" begin
        dir   = mktempdir()
        store = ResourceStore(dir)
        h     = rs_new_resource(store, "http://example/x.metta", UInt64(7))
        p     = rh_path(h)
        @test isfile(p)
        finalize(h)
        @test !isfile(p)
    end

    @testset "finalize renames; close after finalize is a no-op" begin
        dir   = mktempdir()
        store = ResourceStore(dir)
        h     = rs_new_resource(store, "http://example/y.metta", UInt64(3))
        old   = rh_path(h)
        rh_finalize!(h, UInt64(0x1a2b))
        @test !isfile(old)                 # renamed away
        @test length(readdir(dir)) == 1    # finalized file present
        close(h)                           # path === nothing now → no-op, no throw
        @test length(readdir(dir)) == 1
    end

    # R-3: hex timestamp must round-trip through purge (upstream parses decimal).
    @testset "rs_purge_before! parses the hex timestamp prefix (R-3)" begin
        dir   = mktempdir()
        store = ResourceStore(dir)
        h     = rs_new_resource(store, "http://example/z.metta", UInt64(1))
        rh_finalize!(h, UInt64(0x00ff))            # hex digits a–f present
        @test length(readdir(dir)) == 1
        rs_purge_before!(store, UInt64(0x0100))    # 0x00ff < 0x0100 → purged
        @test isempty(readdir(dir))
    end
end
