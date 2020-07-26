module TestSpawnAt
using Test
import ThreadPools: StaticPool
using ThreadPools

include("util.jl")


macro ifv1p4(expr)
    if VERSION >= v"1.4"
        thunk = esc(:(()->($expr)))
        quote
            $thunk()
        end
    end
end


@testset "@tspawnat" begin

    @testset "@normal operation" begin
        obj = TestObj(0)
        function fn!(obj)
            sleep(0.1)
            obj.data = Threads.threadid()
        end
        task = @tspawnat Threads.nthreads() fn!(obj)
        @test obj.data == 0
        wait(task)
        @test obj.data == Threads.nthreads()
    end

    @ifv1p4 begin
        @testset "interpolation" begin
            function foo(x)
                sleep(0.01)
                return x
            end

            x = 1
            expect_sum = 3
            t1 = @tspawnat max(1, Threads.nthreads()) foo($x)
            x += 1
            t2 = @tspawnat max(1, Threads.nthreads()-1) foo($x)
            
            test_sum = fetch(t1) + fetch(t2)
            @test expect_sum == test_sum
        end
    end

    @testset "@out of bounds" begin
        @test_throws AssertionError task = @tspawnat Threads.nthreads()+1 randn()
        @test_throws AssertionError task = @tspawnat 0 randn()
    end

    end
end # module