module TestSpawnAt
using Test
import ThreadPools: StaticPool
using ThreadPools

include("util.jl")

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

    @testset "@out of bounds" begin
        @test_throws AssertionError task = @tspawnat Threads.nthreads()+1 randn()
        @test_throws AssertionError task = @tspawnat 0 randn()
    end

end
end # module