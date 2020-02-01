module TestMaps

using Test
using ThreadPools

include("util.jl")


@testset "maps" begin

    @testset "pmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        @test pmap(fn!, objs) == collect(1:N)
        @test primary
        @inferred pmap(fn!, objs)
    end

    @testset "bmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        @test bmap(fn!, objs) == collect(1:N)
        @inferred bmap(fn!, objs)
    end

    @testset "qmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        @test qmap(fn!, objs) == collect(1:N)
        @test primary
        @inferred qmap(fn!, objs)
    end

    @testset "qbmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        @test qbmap(fn!, objs) == collect(1:N)
        @inferred qbmap(fn!, objs)
    end

    @testset "logpmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        p, r = logpmap(fn!, objs)
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @test primary
        @inferred logpmap(fn!, objs)
    end

    @testset "logbmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        p, r = logbmap(fn!, objs)
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @inferred logbmap(fn!, objs)
    end

    @testset "logqmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        p, r = logqmap(fn!, objs)
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @test primary
        @inferred logqmap(fn!, objs)
    end

    @testset "logqbmap" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        p, r = logqbmap(fn!, objs)
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @inferred logqbmap(fn!, objs)
    end

end

end # module