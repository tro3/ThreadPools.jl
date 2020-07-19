module TestMulitDim

using Test
using ThreadPools

include("util.jl")


@testset "generators" begin

    @testset "tmap" begin
        N = 2 * Threads.nthreads()
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        @test tmap(fn!, (TestObj(x) for x in 1:N)) == collect(1:N)
        @test primary
    end

    @testset "bmap" begin
        N = 2 * Threads.nthreads()
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        @test bmap(fn!, (TestObj(x) for x in 1:N)) == collect(1:N)
        @inferred bmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "qmap" begin
        N = 2 * Threads.nthreads()
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        @test qmap(fn!, (TestObj(x) for x in 1:N)) == collect(1:N)
        @test primary
        @inferred qmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "qbmap" begin
        N = 2 * Threads.nthreads()
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        @test qbmap(fn!, (TestObj(x) for x in 1:N)) == collect(1:N)
        @inferred qbmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "logtmap" begin
        N = 2 * Threads.nthreads()
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        p, r = logtmap(fn!, (TestObj(x) for x in 1:N))
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @test primary
        @inferred logtmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "logbmap" begin
        N = 2 * Threads.nthreads()
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        p, r = logbmap(fn!, (TestObj(x) for x in 1:N))
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @inferred logbmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "logqmap" begin
        N = 2 * Threads.nthreads()
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        p, r = logqmap(fn!, (TestObj(x) for x in 1:N))
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @test primary
        @inferred logqmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "logqbmap" begin
        N = 2 * Threads.nthreads()
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        p, r = logqbmap(fn!, (TestObj(x) for x in 1:N))
        @test r == collect(1:N)
        @test length(p.recs) == N*2
        @inferred logqbmap(fn!, (TestObj(x) for x in 1:N))
    end

    @testset "bthreads" begin
        function test()
            N = 2 * Threads.nthreads()
            @bthreads for x in (TestObj(x) for x in 1:N)
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data += 1
            end
            @test [x.data for x in (TestObj(x) for x in 1:N)] == collect(1:N)
        end
        test()
        test()
    end

    @testset "qthreads" begin
        function test()
            N = 2 * Threads.nthreads()
            primary = Threads.nthreads() == 1
            @qthreads for x in (TestObj(x) for x in 1:N)
                Threads.threadid() == 1 && (primary = true)
                x.data += 1
                sleep(0.001)
            end
            @test [x.data for x in (TestObj(x) for x in 1:N)] == collect(1:N)
            @test primary
        end
        test()
        test()
    end 

end


@testset "2d array" begin

    @testset "tmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        @test tmap(fn!, objs) == [collect(1:N/2) collect(N/2+1:N)]
        @test primary
        @inferred tmap(fn!, objs)
    end

    @testset "bmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        @test bmap(fn!, objs) == [collect(1:N/2) collect(N/2+1:N)]
        @inferred bmap(fn!, objs)
    end

    @testset "qmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        @test qmap(fn!, objs) == [collect(1:N/2) collect(N/2+1:N)]
        @test primary
        @inferred qmap(fn!, objs)
    end

    @testset "qbmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        @test qbmap(fn!, objs) == [collect(1:N/2) collect(N/2+1:N)]
        @inferred qbmap(fn!, objs)
    end

    @testset "logtmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        p, r = logtmap(fn!, objs)
        @test r == [collect(1:N/2) collect(N/2+1:N)]
        @test length(p.recs) == N*2
        @test primary
        @inferred logtmap(fn!, objs)
    end

    @testset "logbmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        p, r = logbmap(fn!, objs)
        @test r == [collect(1:N/2) collect(N/2+1:N)]
        @test length(p.recs) == N*2
        @inferred logbmap(fn!, objs)
    end

    @testset "logqmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        primary = Threads.nthreads() == 1
        fn! = (x) -> begin
            Threads.threadid() == 1 && (primary = true)
            x.data
        end
        p, r = logqmap(fn!, objs)
        @test r == [collect(1:N/2) collect(N/2+1:N)]
        @test length(p.recs) == N*2
        @test primary
        @inferred logqmap(fn!, objs)
    end

    @testset "logqbmap" begin
        N = 2 * Threads.nthreads()
        objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
        fn! = (x) -> begin
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data
        end
        p, r = logqbmap(fn!, objs)
        @test r == [collect(1:N/2) collect(N/2+1:N)]
        @test length(p.recs) == N*2
        @inferred logqbmap(fn!, objs)
    end

    @testset "bthreads" begin
        function test()
            N = 2 * Threads.nthreads()
            objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
            @bthreads for x in objs
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data += 1
            end
            @test [x.data for x in objs] == [collect(2:N/2+1) collect(N/2+2:N+1)]
        end
        test()
        test()
    end

    @testset "qthreads" begin
        function test()
            N = 2 * Threads.nthreads()
            objs = [collect(TestObj(x) for x in 1:N/2) collect(TestObj(x) for x in N/2+1:N)]
            primary = Threads.nthreads() == 1
            @qthreads for x in objs
                Threads.threadid() == 1 && (primary = true)
                x.data += 1
                sleep(0.001)
            end
            @test [x.data for x in objs] == [collect(2:N/2+1) collect(N/2+2:N+1)]
            @test primary
        end
        test()
        test()
    end                             

end


end # module