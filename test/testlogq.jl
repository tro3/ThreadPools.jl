module TestLoggedQueued

using Test
import ThreadPools: LoggedQueuePool
using ThreadPools

include("util.jl")


@testset "LoggedQueuePool" begin

    @testset "pforeach" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            fn! = (x) -> begin
                Threads.threadid() == 1 && (primary = true)
                x.data += 1
            end
            pool = LoggedQueuePool()
            pforeach(pool, fn!, objs)
            @test [x.data for x in objs] == collect(2:N+1)
            @test primary
            @test length(pool.recs) == N*2
            @inferred pforeach(pool, fn!, objs)
            close(pool)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data += 1
            end
            pool = LoggedQueuePool(2)
            pforeach(pool, fn!, objs)
            @test [x.data for x in objs] == collect(2:N+1)
            @test length(pool.recs) == N*2
            @inferred pforeach(pool, fn!, objs)
            close(pool)
        end
    end

    @testset "pmap" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            fn! = (x) -> begin
                Threads.threadid() == 1 && (primary = true)
                x.data
            end
            pool = LoggedQueuePool()
            @test pmap(pool, fn!, objs) == collect(1:N)
            @test primary
            @test length(pool.recs) == N*2
            @inferred pmap(pool, fn!, objs)
            close(pool)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data
            end
            pool = LoggedQueuePool(2)
            @test pmap(pool, fn!, objs) == collect(1:N)
            @test length(pool.recs) == N*2
            @inferred pmap(pool, fn!, objs)
            close(pool)
        end
    end

    @testset "pwith" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pool = pwith(LoggedQueuePool()) do pool
                pforeach(pool, objs) do x
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
            pool = pwith(LoggedQueuePool(2)) do pool
                pforeach(pool, objs) do x
                    Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                    x.data += 1
                end
            end
            @test [x.data for x in objs] == collect(2:N+1)
            @test length(pool.recs) == N*2
        end
    end

    @testset "@pthreads" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pool = LoggedQueuePool()
            @pthreads pool for obj in objs
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
            pool = LoggedQueuePool(2)
            @pthreads pool for obj in objs
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