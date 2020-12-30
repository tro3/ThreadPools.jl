module TestLoggedStatic

using Test
import ThreadPools: LoggedStaticPool
using ThreadPools

include("util.jl")


@testset "LoggedStaticPool" begin

    @testset "tforeach" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            fn! = (x) -> begin
                Threads.threadid() == 1 && (primary = true)
                x.data += 1
            end
            pool = LoggedStaticPool()
            tforeach(fn!, pool, objs)
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
            @test primary
            @test length(pool.recs) == N*2
            @inferred tforeach(fn!, pool, objs)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data += 1
            end
            pool = LoggedStaticPool(2)
            tforeach(fn!, pool, objs)
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
            @test length(pool.recs) == N*2
            @inferred tforeach(fn!, pool, objs)
        end
    end

    @testset "tmap" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            fn! = (x) -> begin
                Threads.threadid() == 1 && (primary = true)
                x.data
            end
            pool = LoggedStaticPool()
            @test tmap(fn!, pool, objs) == collect(1:N)
            close(pool)
            @test primary
            @test length(pool.recs) == N*2
            @inferred tmap(fn!, pool, objs)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data
            end
            pool = LoggedStaticPool(2)
            @test tmap(fn!, pool, objs) == collect(1:N)
            close(pool)
            @test length(pool.recs) == N*2
            @inferred tmap(fn!, pool, objs)
        end
    end

    @testset "twith" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pool = twith(LoggedStaticPool()) do pool
                tforeach(pool, objs) do x
                    Threads.threadid() == 1 && (primary = true)
                    x.data += 1
                end
            end
            @test [x.data for x in objs] == collect(2:N+1)
            @test primary
            @test length(pool.recs) == N*2
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            pool = twith(LoggedStaticPool(2)) do pool
                tforeach(pool, objs) do x
                    Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                    x.data += 1
                end
            end
            @test [x.data for x in objs] == collect(2:N+1)
            @test length(pool.recs) == N*2
        end
    end

    @testset "@tthreads" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pool = LoggedStaticPool()
            @tthreads pool for obj in objs
                Threads.threadid() == 1 && (primary = true)
                obj.data += 1
            end
            close(pool)
            @test primary
            @test [x.data for x in objs] == collect(2:N+1)
            @test length(pool.recs) == N*2
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            pool = LoggedStaticPool(2)
            @tthreads pool for obj in objs
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                obj.data += 1
            end
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
            @test length(pool.recs) == N*2
        end
    end

end

end # module