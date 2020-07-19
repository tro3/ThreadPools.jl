module TestMulitArg

using Test
using ThreadPools

include("util.jl")


@testset "multiarg" begin

    @testset "tmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data + y
        end
        @test tmap(fn!, (TestObj(x) for x in 1:N), adders) == collect(1+1:N+1)
        @test primary
    end

    @testset "bmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data + y
        end
        @test bmap(fn!, (TestObj(x) for x in 1:N), adders) == collect(1+1:N+1)
        @inferred bmap(fn!, (TestObj(x) for x in 1:N), adders)
    end

    @testset "qmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data + y
        end
        @test qmap(fn!, (TestObj(x) for x in 1:N), adders) == collect(1+1:N+1)
        @test primary
        @inferred qmap(fn!, (TestObj(x) for x in 1:N), adders)
    end

    @testset "qbmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data + y
        end
        @test qbmap(fn!, (TestObj(x) for x in 1:N), adders) == collect(1+1:N+1)
        @inferred qbmap(fn!, (TestObj(x) for x in 1:N), adders)
    end

    @testset "logtmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data + y
        end
        p, r = logtmap(fn!, (TestObj(x) for x in 1:N), adders)
        @test r == collect(1+1:N+1)
        @test length(p.recs) == N*2
        @test primary
        @inferred logtmap(fn!, (TestObj(x) for x in 1:N), adders)
    end

    @testset "logbmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data + y
        end
        p, r = logbmap(fn!, (TestObj(x) for x in 1:N), adders)
        @test r == collect(1+1:N+1)
        @test length(p.recs) == N*2
        @inferred logbmap(fn!, (TestObj(x) for x in 1:N), adders)
    end

    @testset "logqmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data + y
        end
        p, r = logqmap(fn!, (TestObj(x) for x in 1:N), adders)
        @test r == collect(1+1:N+1)
        @test length(p.recs) == N*2
        @test primary
        @inferred logqmap(fn!, (TestObj(x) for x in 1:N), adders)
    end

    @testset "logqbmap" begin
        N = 2 * Threads.nthreads()
        adders = [1 for _ in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data + y
        end
        p, r = logqbmap(fn!, (TestObj(x) for x in 1:N), adders)
        @test r == collect(1+1:N+1)
        @test length(p.recs) == N*2
        @inferred logqbmap(fn!, (TestObj(x) for x in 1:N), adders)
    end


    @testset "tforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += y
        end
        tforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @test primary
        @inferred tforeach(fn!, objs, 1:N)
    end

    @testset "bforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += y
        end
        bforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @inferred bforeach(fn!, objs, 1:N)
    end

    @testset "qforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += y
        end
        qforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @test primary
        @inferred qforeach(fn!, objs, 1:N)
    end

    @testset "qbforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += y
        end
        qbforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @inferred qbforeach(fn!, objs, 1:N)
    end

    @testset "logtforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += y
        end
        p = logtforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @test length(p.recs) == N*2
        @test primary
        @inferred logtforeach(fn!, objs, 1:N)
    end

    @testset "logbforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += y
        end
        p = logbforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @test length(p.recs) == N*2
        @inferred logbforeach(fn!, objs, 1:N)
    end

    @testset "logqforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        fn! = (x, y) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data += y
        end
        p = logqforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @test length(p.recs) == N*2
        @test primary
        @inferred logqforeach(fn!, objs, 1:N)
    end

    @testset "logqbforeach" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        fn! = (x, y) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += y
        end
        p = logqbforeach(fn!, objs, 1:N)
        @test [x.data for x in objs] == collect(1:N)*2
        @test length(p.recs) == N*2
        @inferred logqbforeach(fn!, objs, 1:N)
    end

end

      


end # module