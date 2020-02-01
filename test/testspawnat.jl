module TestSpawnAt
using Test
import ThreadPools: StaticPool
using ThreadPools

include("util.jl")


@testset "@spawnat" begin
    obj = TestObj(0)
    function fn!(obj)
        sleep(0.1)
        obj.data = Threads.threadid()
    end
    task = @spawnat Threads.nthreads() fn!(obj)
    @test obj.data == 0
    wait(task)
    @test obj.data == Threads.nthreads()
end

end # module