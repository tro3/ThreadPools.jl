module TestMacros

using Test
using ThreadPools

include("util.jl")


@testset "macros" begin

     @testset "bthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        @bthreads for x in objs
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        @test [x.data for x in objs] == collect(2:N+1)
    end

    @testset "qthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        @qthreads for x in objs
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        @test [x.data for x in objs] == collect(2:N+1)
        @test primary
    end

    @testset "qbthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        @qbthreads for x in objs
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        @test [x.data for x in objs] == collect(2:N+1)
    end

    @testset "logthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        pool = @logthreads for x in objs
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        @test primary
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(collect(Iterators.flatten(values(pool.log)))) == N
    end

    @testset "logbthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        pool = @logbthreads for x in objs
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(collect(Iterators.flatten(values(pool.log)))) == N
    end

    @testset "logqthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        primary = Threads.nthreads() == 1
        pool = @logqthreads for x in objs
            Threads.threadid() == 1 && (primary = true)
            x.data += 1
        end
        @test primary
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(collect(Iterators.flatten(values(pool.log)))) == N
    end

    @testset "logqbthreads" begin
        N = 2 * Threads.nthreads()
        objs = [TestObj(x) for x in 1:N]
        pool = @logqbthreads for x in objs
            Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
            x.data += 1
        end
        @test [x.data for x in objs] == collect(2:N+1)
        @test length(collect(Iterators.flatten(values(pool.log)))) == N
    end
end

end # module