module TestForeach

using Test
using ThreadPools

include("util.jl")


@testset "foreaches" begin

    @testset "tforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        tforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @test primary
        @inferred tforeach(fn!, objs)
    end

    @testset "bforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        bforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @inferred bforeach(fn!, objs)
    end

    @testset "qforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        qforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @test primary
        @inferred qforeach(fn!, objs)
    end

    @testset "qbforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        qbforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @inferred qbforeach(fn!, objs)
    end

    @testset "logtforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        p = logtforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(p.recs) == N*2
        @test primary
        @inferred logtforeach(fn!, objs)
    end

    @testset "logbforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        p = logbforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(p.recs) == N*2
        @inferred logbforeach(fn!, objs)
    end

    @testset "logqforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        p = logqforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(p.recs) == N*2
        @test primary
        @inferred logqforeach(fn!, objs)
    end

    @testset "logqbforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        p = logqbforeach(fn!, objs)
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(p.recs) == N*2
        @inferred logqbforeach(fn!, objs)
    end

end

end # module