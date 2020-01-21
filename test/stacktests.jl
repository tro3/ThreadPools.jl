module TestStacks

using Test
import ThreadPools: QueuePool, LoggedQueuePool
using ThreadPools

include("util.jl")

function fn(x)
    x.data
end

@testset "stack tests" begin

    @testset "QueuePool foreground" begin

        objs = [TestObj(x) for x in 1:64]
        output = []
        pool = QueuePool(1)

        stack = Channel{TestObj}(1024) do stack
            for item in stack
                put!(pool, fn, item)
            end
            close(pool)
        end

        for item in objs
            put!(stack, item)
        end

        for result in results(pool)
            push!(output, result)
            if result % 3 == 0
                put!(stack, TestObj(11))
            end
            if !isready(stack)
                close(stack)
            end
        end

        @test length(output) == 85

    end


    @testset "QueuePool background" begin

        objs = [TestObj(x) for x in 1:64]
        output = []
        pool = QueuePool(2)

        stack = Channel{TestObj}(1024) do stack
            for item in stack
                put!(pool, fn, item)
            end
            close(pool)
        end

        for item in objs
            put!(stack, item)
        end

        for result in results(pool)
            push!(output, result)
            if result % 3 == 0
                put!(stack, TestObj(11))
            end
            if !isready(stack)
                close(stack)
            end
        end

        @test length(output) == 85

    end


    @testset "LoggedQueuePool foreground" begin

        objs = [TestObj(x) for x in 1:64]
        output = []
        pool = LoggedQueuePool(1)

        stack = Channel{TestObj}(1024) do stack
            for item in stack
                put!(pool, fn, item)
            end
            close(pool)
        end

        for item in objs
            put!(stack, item)
        end

        for result in results(pool)
            push!(output, result)
            if result % 3 == 0
                put!(stack, TestObj(11))
            end
            if !isready(stack)
                close(stack)
            end
        end

        @test length(output) == 85
        @test length(collect(keys(pool.log))) == Threads.nthreads()
        @test sum(length, values(pool.log)) == 85

    end


    @testset "LoggedQueuePool background" begin

        objs = [TestObj(x) for x in 1:64]
        output = []
        pool = LoggedQueuePool(2)

        stack = Channel{TestObj}(1024) do stack
            for item in stack
                put!(pool, fn, item)
            end
            close(pool)
        end

        for item in objs
            put!(stack, item)
        end

        for result in results(pool)
            push!(output, result)
            if result % 3 == 0
                put!(stack, TestObj(11))
            end
            if !isready(stack)
                close(stack)
            end
        end

        @test length(output) == 85
        @test length(collect(keys(pool.log))) == Threads.nthreads()-1
        @test sum(length, values(pool.log)) == 85

    end

end

end # module