module TestSpawnAt
using Test
import ThreadPools: StaticPool
using ThreadPools

include("util.jl")

@testset "@pspawnat" begin

    @testset "@normal operation" begin
        obj = TestObj(0)
        function fn!(obj)
            sleep(0.1)
            obj.data = Threads.threadid()
        end
        task = @pspawnat Threads.nthreads() fn!(obj)
        @test obj.data == 0
        wait(task)
        @test obj.data == Threads.nthreads()
    end

    @testset "@out of bounds" begin
        @test_throws AssertionError task = @pspawnat Threads.nthreads()+1 randn()
        @test_throws AssertionError task = @pspawnat 0 randn()
    end

end
end # module