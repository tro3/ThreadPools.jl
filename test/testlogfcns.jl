
module TestLoggedFunctions

using Test
import ThreadPools: LoggedStaticPool
using ThreadPools

include("util.jl")

@testset "log functions" begin

    @testset "read/write logs" begin
        N = 2 * Threads.nthreads()
        pool = LoggedStaticPool()
        tforeach(pool, x->sleep(0.01*x), 1:N)
        close(pool)
        dumplog("_tmp.log", pool)
        log2 = readlog("_tmp.log")
        @test pool.log == log2
        rm("_tmp.log")
    end

    @testset "showactivity" begin
        io = IOBuffer()
        showactivity(io, "$(@__DIR__)/testlog.txt", 0.1, nthreads=4)
        @test replace(String(take!(io)), r"\s+\n"=>"\n") == """0.000   -   -   -   -
0.100   4   1   3   2
0.200   4   5   3   2
0.300   4   5   3   6
0.400   4   5   7   6
0.500   8   5   7   6
0.600   8   5   7   6
0.700   8   -   7   6
0.800   8   -   7   6
0.900   8   -   7   -
1.000   8   -   7   -
1.100   8   -   -   -
1.200   8   -   -   -
1.300   -   -   -   -
1.400   -   -   -   -
1.500   -   -   -   -
"""
    end

    @testset "showstats" begin
        io = IOBuffer()
        showstats(io, "$(@__DIR__)/testlog.txt")
        @test String(take!(io)) == """

        Total duration: 1.212 s
        Number of jobs: 8
        Average job duration: 0.457 s
        Minimum job duration: 0.11 s
        Maximum job duration: 0.805 s
    
        Thread 1: Duration 1.211 s, Gap time 0.0 s
        Thread 2: Duration 0.616 s, Gap time 0.0 s
        Thread 3: Duration 1.024 s, Gap time 0.0 s
        Thread 4: Duration 0.805 s, Gap time 0.0 s
    """
    end

end

end # module