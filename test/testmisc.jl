module TestMisc

using Test
using ThreadPools

include("util.jl")


@testset "miscellaneous" begin

    @testset "issue25" begin
        a = []
        @bthreads for x in 1:3
            if x == 2
                continue
            end
            push!(a, x)
        end
        @test sort(a) == [1,3]

        a = []
        @qthreads for x in 1:3
            if x == 2
                continue
            end
            push!(a, x)
        end
        @test sort(a) == [1,3]

        a = []
        @qbthreads for x in 1:3
            if x == 2
                continue
            end
            push!(a, x)
        end
        @test sort(a) == [1,3]
    end

end

end