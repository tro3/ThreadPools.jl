
const LogItem = Tuple{Int, Int, Char, Float64} #Jobnum, Thread ID, Start:Stop, Time
const Job = Tuple{Int, Int, Float64, Float64} #Jobnum, Thread ID, Start Time, Stop Time

"""
    LoggingThreadPool(io, allow_primary=false)

A ThreadPool that will index and log the start/stop times of each Task `put`
into the pool.  The log format is:

```
522 3 S 7.932999849319458
523 4 S 7.932999849319458
522 3 P 8.823155343098272
 ^  ^ ^    ^
 |  | |    |
 |  | |    Time
 |  | S=Start, P=Stop 
 |  Thread ID
 Job #
```

"""
function LoggingThreadPool(io::IO, allow_primary=false)
    isreadonly(io) && error("LoggingThreadPool given a readonly log handle")

    jobnum = Threads.Atomic{Int}(1)
    t0 = time()

    logger = Channel{LogItem}(16*1024) do c
        for item in c
            job, tid, st, t = item
            write(io, "$job $tid $st $t\n")
        end
    end

    handler = (pool) -> begin
        tid = Threads.threadid()
        for t in pool.inq
            job = Threads.atomic_add!(jobnum, 1)
            put!(logger, (job, tid, 'S', time()-t0))
            schedule(t)
            wait(t)
            tend = time()-t0
            put!(logger, (job, tid, 'P', tend))
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


function readlog(io::IO)
    result = Dict{Int, Vector{Job}}()
    starts = Dict{Int, Float64}()
    job = 0
    tid = 0
    start = true
    t = 0.0
    for (i,line) in enumerate(readlines(io))
        try
            (a,b,c,d) = split(line)
            job = parse(Int, a)
            tid = parse(Int, b)
            start = c == "S"
            t = parse(Float64, d)
        catch
            error("Malformed log entry, line $i: $line")
        end
        if start
            starts[job] = t
        else
            haskey(starts, job) || error("Stop encountered before start: line $i, job $job")
            push!(get!(result, tid, Job[]), (job, tid, starts[job], t))
        end
    end
    return result
end

readlog(fname::String) = readlog(open(fname))


duration(job::Job) = job[4] - job[3]
active(job::Job, t) = t >= job[3] && t < job[4]

duration(jobs::Vector{Job}) = maximum(j[4] for j in jobs) - minimum(j[3] for j in jobs) # Nonoptimized
jobcount(jobs::Vector{Job}, t) = length(filter(j -> active(j,t), jobs))
jobactive(jobs::Vector{Job}, t) = first(filter(j -> active(j,t), jobs))


_pad(n) = string([" " for i in 1:n]...)

function _formatjob(log, tid, t, width)
    if iseven(width)
        half = div(width, 2)
        none = string(_pad(half), "-", _pad(half-1))
    else
        half = div(width-1, 2)
        none = string(_pad(half), "-", _pad(half))
    end
    haskey(log, tid) || return none
    jobs = log[tid]
    count = jobcount(jobs, t)
    count > 0 || return none
    jobstr = string(jobactive(jobs, t)[1])
    return string(_pad(width-2-length(jobstr)), count > 1 ? "*" : " ", jobstr)
end

function showactivity(log::Dict{Int, Vector{Job}}, dt, t0=0, t1=Inf, nthreads=Inf)
    maxj = maximum(j[1] for jobs in values(log) for j in jobs)
    width = length(string(maxj)) + 3

    maxt = maximum(duration(x) for x in values(log))
    t1 = min(t1, (ceil(maxt/dt)+2)*dt)

    t = floor(t0/dt)*dt
    nonecnt = 0
    nthreads = min(nthreads, Threads.nthreads())
    while t <= t1
        tstr = round(t; digits=3)
        println("$tstr $(string([_formatjob(log, tid, t, width) for tid in 1:nthreads]...))")
        t += dt
    end
end

showactivity(fname::String, dt, t0=0, t1=Inf, nthreads=Inf) = showactivity(readlog(fname), dt, t0, t1, nthreads)
