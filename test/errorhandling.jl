
module TestErrorHandling

using Test
using ThreadPools


function testfunc(err)
    fn(x) = x == err && error("Error")
    return fn
end

@testset "exception handling" begin

    @testset "foreach functions" begin
        for i in 1:16
            @test_throws TaskFailedException tforeach(testfunc(i), 1:16)
            @test_throws TaskFailedException bforeach(testfunc(i), 1:16)
            @test_throws TaskFailedException qforeach(testfunc(i), 1:16)
            @test_throws TaskFailedException qbforeach(testfunc(i), 1:16)
        end
    end

    @testset "map functions" begin
        for i in 1:16
            @test_throws TaskFailedException tmap(testfunc(i), 1:16)
            @test_throws TaskFailedException bmap(testfunc(i), 1:16)
            @test_throws TaskFailedException qmap(testfunc(i), 1:16)
            @test_throws TaskFailedException qbmap(testfunc(i), 1:16)
        end
    end

    @testset "macros" begin
        for i in 1:16
            @test_throws TaskFailedException begin
                @bthreads for j in 1:16
                    testfunc(i)(j)
                end 
            end 
            @test_throws TaskFailedException begin
                @qthreads for j in 1:16
                    testfunc(i)(j)
                end 
            end 
            @test_throws TaskFailedException begin
                @qbthreads for j in 1:16
                    testfunc(i)(j)
                end 
            end
        end 
    end
end

@testset "stop on error" begin
    for fn in [tforeach, bforeach, qforeach, qbforeach, tmap, bmap, qmap, qbmap]
        let
            count = Threads.Atomic{Int}(0)
            function testfn(x)
                if x == 2
                    sleep(0.001)
                    error("Error")
                else
                    sleep(0.02)
                    Threads.atomic_add!(count, 1)
                end
            end
            @test_throws TaskFailedException fn(testfn, 1:16)
            @test count[] <= Threads.nthreads()
        end
    end
end

end