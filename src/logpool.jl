

const LogItem = Tuple{Int, Int, Bool, Float64} #Jobnum, Thread ID, Start:Stop, Time 

"""
    LoggingThreadPool(io, allow_primary=false)

A ThreadPool that will index and log the start/stop times of each Task `put`
into the pool.  The log format is:

```
522 S 7.932999849319458
523 S 
522 P 7.932999849319458
```

"""
function LoggingThreadPool(io::IO, allow_primary=false)
    jobnum = Threads.Atomic{Int}(1)
    t0 = time()

    logger = Channel{LogItem}(16*1024) do c
        for item in c
            job, tid, start, t = item
            st = start ? "S" : "P"
            write(io, "$job $tid $st $t\n")
        end
    end

    handler = (pool) -> begin
        tid = Threads.threadid()
        for t in pool.inq
            job = jobnum[]
            Threads.atomic_add!(jobnum, 1)
            put!(logger, (job, tid, true, time()-t0))
            schedule(t)
            wait(t)
            tend = time()-t0
            put!(logger, (job, tid, false, tend))
            put!(pool.outq, t)
            Threads.atomic_sub!(pool.cnt, 1)
        end
    end

    pool = ThreadPool(allow_primary, handler)

    @async begin
        while pool.outq.state != :closed
            yield()
            sleep(0.1)
        end
        close(logger)
    end

    return pool
end
