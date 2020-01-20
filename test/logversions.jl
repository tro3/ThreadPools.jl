
module LoggingCases

using Test
import ThreadPools
using ThreadPools

include("util.jl")

@testset "showactivity" begin
    io = IOBuffer()
    ThreadPools.showactivity(io, "$(@__DIR__)/testlog.txt", 0.1, nthreads=4)
    @test replace(String(take!(io)), r"\s+\n"=>"\n") == """0.000   -   -   -   -
0.100   -   2   1   3
0.200   -   2   4   3
0.300   -   5   4   3
0.400   -   5   4   6
0.500   -   5   4   6
0.600   -   5   7   6
0.700   -   5   7   6
0.800   -   8   7   6
0.900   -   8   7   6
1.000   -   8   7   -
1.100   -   8   7   -
1.200   -   8   7   -
1.300   -   8   -   -
1.400   -   8   -   -
1.500   -   8   -   -
1.600   -   -   -   -
1.700   -   -   -   -
"""
end

@testset "showstats" begin
    io = IOBuffer()
    ThreadPools.showstats(io, "$(@__DIR__)/testlog.txt")
    @test String(take!(io)) == """

    Total duration: 1.542 s
    Number of jobs: 8
    Average job duration: 0.462 s
    Minimum job duration: 0.111 s
    Maximum job duration: 0.82 s

    Thread 2: Duration 1.542 s, Gap time 0.0 s
    Thread 3: Duration 1.23 s, Gap time 0.0 s
    Thread 4: Duration 0.925 s, Gap time 0.0 s
"""
end

if Threads.nthreads() > 1
    @testset "logbgforeach" begin
        io = IOBuffer()
        ThreadPools.logbgforeach(x -> sleep(0.01*x), io, collect(1:Threads.nthreads()*2))
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test !haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        ThreadPools.logbgforeach(x -> sleep(0.01*x), "_tmp.txt", collect(1:Threads.nthreads()*2))
        log = ThreadPools.readlog("_tmp.txt")
        @test !haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp.txt")
    end

    @testset "logfgforeach" begin
        io = IOBuffer()
        ThreadPools.logfgforeach(x -> sleep(0.01*x), io, collect(1:Threads.nthreads()*2))
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        ThreadPools.logfgforeach(x -> sleep(0.01*x), "_tmp.txt", collect(1:Threads.nthreads()*2))
        log = ThreadPools.readlog("_tmp.txt")
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp.txt")
    end

    @testset "logbgmap" begin
        io = IOBuffer()
        r = ThreadPools.logbgmap(io, collect(1:Threads.nthreads()*2)) do x
            sleep(0.01*x)
            x^2
        end
        @test r == collect(1:Threads.nthreads()*2) .^ 2
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test !haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        r = ThreadPools.logbgmap("_tmp.txt", collect(1:Threads.nthreads()*2)) do x
            sleep(0.01*x)
            x^2
        end
        @test r == collect(1:Threads.nthreads()*2) .^ 2
        log = ThreadPools.readlog("_tmp.txt")
        @test !haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp.txt")
    end

    @testset "logfgmap" begin
        io = IOBuffer()
        r = ThreadPools.logfgmap(io, collect(1:Threads.nthreads()*2)) do x
            sleep(0.01*x)
            x^2
        end
        @test r == collect(1:Threads.nthreads()*2) .^ 2
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        r = ThreadPools.logfgmap("_tmp.txt", collect(1:Threads.nthreads()*2)) do x
            sleep(0.01*x)
            x^2
        end
        @test r == collect(1:Threads.nthreads()*2) .^ 2
        log = ThreadPools.readlog("_tmp.txt")
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp.txt")
    end

    @testset "@logbgthreads" begin
        io = IOBuffer()
        ThreadPools.@logbgthreads io for x in 1:Threads.nthreads()*2
            sleep(0.01*x)
        end
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test !haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        ThreadPools.@logbgthreads "_tmp.txt" for x in 1:Threads.nthreads()*2
            sleep(0.01*x)
        end
        log = ThreadPools.readlog("_tmp.txt")
        @test !haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp.txt")
    end

    @testset "@logfgthreads" begin
        io = IOBuffer()
        ThreadPools.@logfgthreads io for x in 1:Threads.nthreads()*2
            sleep(0.01*x)
        end
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        ThreadPools.@logfgthreads "_tmp.txt" for x in 1:Threads.nthreads()*2
            sleep(0.01*x)
        end
        log = ThreadPools.readlog("_tmp.txt")
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp.txt")
    end

    @testset "@logthreads" begin
        io = IOBuffer()
        ThreadPools.@logthreads io for x in 1:Threads.nthreads()*2
            sleep(0.01*x)
        end
        io = IOBuffer(take!(io))
        log = ThreadPools.readlog(io)
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2

        ThreadPools.@logthreads "_tmp2.txt" for x in 1:Threads.nthreads()*2
            sleep(0.01*x)
        end
        log = ThreadPools.readlog("_tmp2.txt")
        @test haskey(log, 1)
        @test sum(length, values(log)) == Threads.nthreads()*2
        rm("_tmp2.txt")
    end

end

if Threads.nthreads() == 1
    @test_throws SystemError ThreadPools.logbgforeach(x -> sleep(0.01*x), "fail.txt", collect(1:Threads.nthreads()*2))
    @test_throws SystemError ThreadPools.logfgforeach(x -> sleep(0.01*x), "fail.txt", collect(1:Threads.nthreads()*2))
    @test_throws SystemError ThreadPools.logfgmap(x -> sleep(0.01*x), "fail.txt", collect(1:Threads.nthreads()*2))
    @test_throws SystemError ThreadPools.logbgmap(x -> sleep(0.01*x), "fail.txt", collect(1:Threads.nthreads()*2))
    @test !isfile("fail.txt")
end

end