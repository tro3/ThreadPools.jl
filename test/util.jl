
function work(job)
    endtime = time() + 0.1
    while time() < endtime # Blocking wait
        nothing
    end
    return (job, Threads.threadid())
end

mutable struct TestObj
    data :: Int
end