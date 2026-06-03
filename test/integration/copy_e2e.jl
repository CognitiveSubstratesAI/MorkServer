# test/integration/copy_e2e.jl — ports copy command tests
# Tests /copy/<src>/<dst> — mirrors wz.graft(&rz) in Rust server
#
# Spins up its own MorkServer on a private port — was originally
# designed to run against a developer-launched server on :8080, but
# that didn't work in `runtests.jl` (2026-05-30).
using MORK, MorkServer, Test, HTTP, JSON3

const COPY_PORT = 9903
const COPY_BASE = "http://127.0.0.1:$COPY_PORT"

let
    ss = ServerSpace()
    serve_background!(ss, COPY_PORT)
    deadline = time() + 15.0
    while time() < deadline
        try
            ;
            HTTP.get("$COPY_BASE/status/-"; readtimeout=1, connect_timeout=1);
            break
        catch
            ;
            sleep(0.2);
        end
    end
end

function _copy_get(path)
    r = HTTP.get("$COPY_BASE$path"; readtimeout=10, connect_timeout=5)
    r.status, String(r.body)
end
function _copy_post(path, body="")
    r = HTTP.post("$COPY_BASE$path", [], body; readtimeout=10, connect_timeout=5)
    r.status, String(r.body)
end
function _copy_wait_status(expr_url; timeout_s=5.0)
    deadline = time() + timeout_s
    while time() < deadline
        try
            j = JSON3.read(HTTP.get("$COPY_BASE/status/$expr_url"; readtimeout=2).body)
            s = String(j[:status])
            s ∉ ("locked", "counting") && return j
        catch
            ;
        end
        sleep(0.1)
    end
    nothing
end

_copy_get("/clear/%24")
sleep(0.3)

@testset "copy — copies atoms from src prefix to dst prefix" begin

    status, body = _copy_post("/upload/\$/\$", "(foo 1)\n(foo 2)\n(foo 3)\n")
    @test status == 200
    @test body == "ACK. Upload Successful"

    # Copy (foo $x) → (bar $x) — src/dst must match the arity of stored atoms
    status, body = _copy_get("/copy/(foo%20%24x)/(bar%20%24x)")
    @test status == 200
    @test occursin("ACK", body)

    # Count atoms under (bar $x) — should be 3
    _copy_get("/count/(bar%20%24x)")
    j_bar = _copy_wait_status("(bar%20%24x)")
    @test j_bar !== nothing
    @test j_bar[:count] == 3

    # Source atoms still present after copy
    _copy_get("/count/(foo%20%24x)")
    j_foo = _copy_wait_status("(foo%20%24x)")
    @test j_foo !== nothing
    @test j_foo[:count] == 3

    # Copy non-existent prefix → 200, no error
    status2, _ = _copy_get("/copy/(nosuchprefix)/(dst2)")
    @test status2 == 200

end

_copy_get("/clear/%24")

try
    ;
    HTTP.get("$COPY_BASE/stop");
catch
    ;
end
