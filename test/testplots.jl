module TestPlotRecipes

using Test
using Plots
import ThreadPools: LoggedQueuePool, LoggedStaticPool
using ThreadPools

include("util.jl")


@testset "plot recipes" begin

    @testset "log" begin
        plot(readlog("testlog.txt"))
        png("_test.png")
        @test isfile("_test.png")
        rm("_test.png")
    end

    @testset "LoggedQueuePool" begin
        pool = LoggedQueuePool()
        pool.log = readlog("testlog.txt")
        plot(pool)
        close(pool)
        png("_test.png")
        @test isfile("_test.png")
        rm("_test.png")
    end

    @testset "LoggedStaticPool" begin
        pool = LoggedStaticPool(1:Threads.nthreads(), ReentrantLock(), [], time_ns(), readlog("testlog.txt"))
        plot(pool)
        close(pool)
        png("_test.png")
        @test isfile("_test.png")
        rm("_test.png")
    end
end

end # module