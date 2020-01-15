
module TestUseCases

using Test
import ThreadPools
using ThreadPools

include("util.jl")

@testset "bgforeach with multiple args" begin
    N = Threads.nthreads() == 1 ? 2 : (Threads.nthreads()-1)*2
    xs = collect(1:N)
    ys = collect(1:N) .+ 2
    objs = [TestObj(x) for x in 1:N]
    bgforeach(objs, xs, ys) do obj, x, y
        obj.data = 2x + y
    end
    @test [x.data for x in objs] == 2 .* collect(1:N) + (collect(1:N) .+ 2)

end

@testset "bgmap with multiple args" begin
    N = Threads.nthreads() == 1 ? 2 : (Threads.nthreads()-1)*2
    xs = collect(1:N)
    ys = collect(1:N) .+ 2
    result = bgmap((x,y) -> 2x+y, xs, ys)
    @test result == 2 .* collect(1:N) + (collect(1:N) .+ 2)
end

@testset "Nested pooling" begin
    N = 2*(Threads.nthreads()-1)
    objs = [TestObj(x) for x in 1:N^2]
    tasks = []
    @bgthreads for i in 1:N
        @bgthreads for j in 1:N
            Threads.threadid() == 1 && error("Task on primary")
            objs[(i-1)*N + j].data += 1
        end
    end
    @test [x.data for x in objs] == collect(2:N^2+1)
end

end