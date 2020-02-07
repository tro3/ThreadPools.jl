module TestStatic

using Test
import ThreadPools: StaticPool
using ThreadPools

include("util.jl")


@testset "StaticPool" begin

    @testset "tforeach" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            fn! = (x) -> begin
                Threads.threadid() == 1 && (primary = true)
                x.data += 1
            end
            pool = StaticPool()
            tforeach(pool, fn!, objs)
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
            @test primary
            @inferred tforeach(pool, fn!, objs)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data += 1
            end
            pool = StaticPool(2)
            tforeach(pool, fn!, objs)
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
            @inferred tforeach(pool, fn!, objs)
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
            pool = StaticPool()
            @test tmap(pool, fn!, objs) == collect(1:N)
            close(pool)
            @test primary
            @inferred tmap(pool, fn!, objs)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            fn! = (x) -> begin
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                x.data
            end
            pool = StaticPool(2)
            @test tmap(pool, fn!, objs) == collect(1:N)
            close(pool)
            @inferred tmap(pool, fn!, objs)
        end
    end

    @testset "pwith" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pwith(StaticPool()) do pool
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
            pwith(StaticPool(2)) do pool
                tforeach(pool, objs) do x
                    Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                    x.data += 1
                end
            end
            @test [x.data for x in objs] == collect(2:N+1)
        end
    end

    @testset "@pthreads" begin
        @testset "foreground" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            primary = Threads.nthreads() == 1
            pool = StaticPool()
            @pthreads pool for obj in objs
                Threads.threadid() == 1 && (primary = true)
                obj.data += 1
            end
            close(pool)
            @test primary
            @test [x.data for x in objs] == collect(2:N+1)
        end

        @testset "background" begin
            N = 2 * Threads.nthreads()
            objs = [TestObj(x) for x in 1:N]
            pool = StaticPool(2)
            @pthreads pool for obj in objs
                Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
                obj.data += 1
            end
            close(pool)
            @test [x.data for x in objs] == collect(2:N+1)
        end
    end

end

end # module