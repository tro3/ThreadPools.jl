
module TestBasics

using Test
import ThreadPools
using ThreadPools

include("util.jl")


@testset "bgforeach" begin
    N = Threads.nthreads() == 1 ? 2 : (Threads.nthreads()-1)*2
    objs = [TestObj(x) for x in 1:N]
    fn! = (x) -> begin
        Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
        x.data += 1
    end
    bgforeach(fn!, objs)
    @test [x.data for x in objs] == collect(2:N+1)
    @inferred bgforeach(fn!, objs)
end

@testset "bgmap" begin
    N = Threads.nthreads() == 1 ? 2 : (Threads.nthreads()-1)*2
    objs = [TestObj(x) for x in 1:N]
    fn = x -> begin
        Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
        x.data
    end
    @test bgmap(fn, objs) == collect(1:N)
    @inferred bgmap(fn, objs)
end

@testset "@bgthreads" begin
    N = Threads.nthreads() == 1 ? 2 : (Threads.nthreads()-1)*2
    objs = [TestObj(x) for x in 1:N]
    @bgthreads for obj in objs
        Threads.nthreads() == 1 || Threads.threadid() == 1 && error("Task on primary")
        obj.data += 1
    end
    @test [x.data for x in objs] == collect(2:N+1)
end


if Threads.nthreads() > 1
    @testset "Task distribution" begin
        pool = ThreadPool()
        N = (Threads.nthreads()-1)*2
        results = []
        @test isactive(pool) == false
        @async begin
            for i in 1:N
                put!(pool, work, i)
            end
            close(pool)
        end
        sleep(0.1)
        @test isactive(pool) == true
        for t in pool
            push!(results, fetch(t))
        end
        sort!(results)
        @test length(filter(x->x[2] == 1, results)) == 0
        for i in 2:Threads.nthreads()
            @test length(filter(x->x[2] == i, results)) == 2
        end
    end
end


end