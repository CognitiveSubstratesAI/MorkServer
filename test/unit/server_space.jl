using Test
using MorkServer
using MorkServer: StatusMap, sm_get_read_permission, sm_get_write_permission,
    sm_release_read!, sm_release_write!

pb(s) = Vector{UInt8}(s)   # paths are Vector{UInt8}, not CodeUnits

@testset "ServerSpace permissions (unit)" begin
    # S-1 (ZipperTracker parity): conflict detection must be PREFIX-aware, not
    # exact-path. Pre-fix a writer at "P:" did not block a writer at "P:x" (different
    # dict keys) → concurrent overlapping writes to btm. These assertions fail on the
    # exact-path-only version.
    @testset "writer blocks overlapping writer/reader (prefix-aware)" begin
        sm = StatusMap()
        w = sm_get_write_permission(sm, pb("P:"))
        @test w !== nothing
        @test sm_get_write_permission(sm, pb("P:x")) === nothing   # extension overlaps
        @test sm_get_read_permission(sm, pb("P:x")) === nothing   # reader vs writer overlap
        @test sm_get_write_permission(sm, pb("P")) === nothing   # prefix overlaps
        @test sm_get_write_permission(sm, pb("Q:")) !== nothing   # disjoint is fine
        sm_release_write!(sm, w)
        wx = sm_get_write_permission(sm, pb("P:x"))                # freed after release
        @test wx !== nothing
        sm_release_write!(sm, wx)
    end

    @testset "readers coexist (even overlapping); writer then blocked" begin
        sm = StatusMap()
        r1 = sm_get_read_permission(sm, pb("R:"))
        r2 = sm_get_read_permission(sm, pb("R:y"))   # overlapping reader is allowed
        @test r1 !== nothing && r2 !== nothing
        @test sm_get_write_permission(sm, pb("R:y")) === nothing   # writer vs active readers
        sm_release_read!(sm, r1)
        @test sm_get_write_permission(sm, pb("R:y")) === nothing   # r2 still holds overlap
        sm_release_read!(sm, r2)
        w = sm_get_write_permission(sm, pb("R:y"))                 # all readers gone
        @test w !== nothing
        sm_release_write!(sm, w)
    end
end
