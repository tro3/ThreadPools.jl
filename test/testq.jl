module TestQueued

using Test
import ThreadPools: QueuePool
using ThreadPools

include("util.jl")


@testset "QueuePool" begin

    @testset "tforeach" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            fn! = (x) -> begin
                Threads.threadid() == 1 && (primary = true)
                x.data += 1
            end
            pool = QueuePool()
            tforeach(fn!, pool, objs)
            @test primary
            @test [x.data for x in objs] == collect(2:N+1)
            @inferred tforeach(fn!, pool, objs)
            close(pool)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data += 1
            end
            pool = QueuePool(2)
            tforeach(fn!, pool, objs)
            @test [x.data for x in objs] == collect(2:N+1)
            @inferred tforeach(fn!, pool, objs)
            close(pool)
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
            pool = QueuePool()
            @test tmap(fn!, pool, objs) == collect(1:N)
            @test primary
            @inferred tmap(fn!, pool, objs)
            close(pool)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data
            end
            pool = QueuePool(2)
            @test tmap(fn!, pool, objs) == collect(1:N)
            @inferred tmap(fn!, pool, objs)
            close(pool)
        end
    end

    @testset "twith" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            twith(QueuePool()) do pool
                tforeach(pool, objs) do x
                    Threads.threadid() == 1 && (primary = true)
                    x.data += 1
                end
            end
            @test [x.data for x in objs] == collect(2:N+1)
            @test primary
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            twith(QueuePool(2)) do pool
                tforeach(pool, objs) do x
                    Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                    x.data += 1
                end
            end
            @test [x.data for x in objs] == collect(2:N+1)
        end
    end

    @testset "@tthreads" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pool = QueuePool()
            @tthreads pool for obj in objs
                Threads.threadid() == 1 && (primary = true)
                obj.data += 1
            end
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
            @test primary
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            pool = QueuePool(2)
            @tthreads pool for obj in objs
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                obj.data += 1
            end
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
        end
    end

end

end # module