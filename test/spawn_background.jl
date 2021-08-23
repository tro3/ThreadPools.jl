module TestSpawnBackground

using Test
using ThreadPools
using Statistics

# Put in the function to test this in compiled form
# to make sure there is no yield etc introduced from running interpreted
function uses_all_threads()
    bg_nthreads = Threads.nthreads() - 1
    bg_threads = zeros(bg_nthreads)
    futures = map(1:bg_nthreads) do i
        return spawn_background() do
            id = Threads.threadid()
            bg_threads[id - 1] = id
            return id
        end
    end
    foreach(wait, futures)
    return sum(bg_threads) == sum(2:(bg_nthreads + 1))
end

function busy_wait(time_s)
    t = time()
    while time() - t < time_s
    end
    return
end

function count_occurence(list)
    occurences = Dict{Int,Int}()
    for elem in list
        i = get!(occurences, elem, 0)
        occurences[elem] = i + 1
    end
    return occurences
end

function spam_threads(f, spam_factor)
    bg_nthreads = Threads.nthreads() - 1
    n_executions = bg_nthreads * spam_factor
    thread_ids = []
    time_spent = @elapsed begin
        futures = map(1:n_executions) do i
            return spawn_background() do
                f()
                return Threads.threadid()
            end
        end
        thread_ids = map(fetch, futures)
    end
    return time_spent, thread_ids
end

function spam_threads_busy(time_waiting, spam_factor)
    return spam_threads(spam_factor) do
        return busy_wait(time_waiting)
    end
end

@testset "threading" begin
    nthreads = Threads.nthreads()
    bg_nthreads = nthreads - 1
    if bg_nthreads == 0
        @test fetch(spawn_background(()-> Threads.threadid())) == 1
    else
        @testset "scheduling" begin
            # When we quickly schedule nthreads work items, the implementation should use all threads
            @test uses_all_threads()

            spam_factor = 5
            time_spent, thread_ids = spam_threads(() -> nothing, spam_factor)
            occurences = count_occurence(thread_ids)
            # We should spread out work to all threads when spamming lots of tasks
            @test all(x -> x in keys(occurences), 2:bg_nthreads)
            # a few threads may get more work items, but the mean should be equal to the spamfactor
            @test spam_factor == mean(values(occurences))

            time_spent, thread_ids = spam_threads_busy(0.5, spam_factor)
            occurences = count_occurence(thread_ids)
            @test all(x -> x in keys(occurences), 2:bg_nthreads)
            @test spam_factor == mean(values(occurences))
            # I'm not sure how stable this will be on the CI, we may need to tweak the atol
            @test time_spent ≈ 0.5 * spam_factor atol = 0.1
        end
        @testset "Queue contains all threads, after work is done" begin
            @test length(unique(ThreadPools.AVAILABLE_THREADS[].data)) == bg_nthreads
        end
    end

    @testset "error handling" begin
        @test_throws CapturedException checked_fetch(spawn_background(() -> error("hey")))
    end

end

end
