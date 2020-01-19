
import Printf: @sprintf

const LogItem = Tuple{Int, Int, Char, Float64} #Jobnum, Thread ID, Start:Stop, Time

struct Job
    id    :: Int
    tid   :: Int
    start :: Float64
    stop  :: Float64
end


"""
    ThreadPools.LoggingThreadPool(io, allow_primary=false)

A ThreadPool that will index and log the start/stop times of each Task `put`
into the pool.  The log format is:

```
522 3 S 7.932999849319458
523 4 S 7.932999849319458
522 3 P 8.823155343098272
  ^ ^ ^ ^
  | | | |
  | | | Time
  | | S=Start, P=Stop 
  | Thread ID
 Job #
```
and is parsed by the [`readlog`](@ref) and [`showactivity`](@ref) commands.
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

"""
    ThreadPools.readlog(io) -> Dict of (thread # => job list)

Analyzes the output of a [`LoggingThreadPool`](@ref) and produces the history
of each job on each thread.  

Each job in the job list is a struct of:
```
struct Job
    id    :: Int
    tid   :: Int
    start :: Float64
    stop  :: Float64
end
```
The default sorting order of the jobs in each thread are by stop time.  `io`
can either be an IO object or a filename. 

# Example
```julia
julia> log = ThreadPools.readlog("mylog.txt")
Dict{Int64,Array{ThreadPools.Job,1}} with 3 entries:
  4 => ThreadPools.Job[Job(3, 4, 0.016, 0.327), Job(6, 4, 0.327, 0.928)]
  2 => ThreadPools.Job[Job(2, 2, 0.016, 0.233), Job(5, 2, 0.233, 0.749)]
  3 => ThreadPools.Job[Job(1, 3, 0.016, 0.139), Job(4, 3, 0.139, 0.546)]
```
"""
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
            push!(get!(result, tid, Job[]), Job(job, tid, starts[job], t))
        end
    end
    close(io)
    return result
end

readlog(fname::String) = readlog(open(fname))


duration(job::Job) = job.stop - job.start
active(job::Job, t) = t >= job.start && t < job.stop

duration(jobs::Vector{Job}) = maximum(j.stop for j in jobs) - minimum(j.start for j in jobs) # Nonoptimized
jobcount(jobs::Vector{Job}, t) = length(filter(j -> active(j,t), jobs))
jobactive(jobs::Vector{Job}, t) = first(filter(j -> active(j,t), jobs))


_pad(n) = string([" " for i in 1:n]...)

function _formatjob(log, tid, t, width)
    none = string(_pad(width-2), "- ")
    haskey(log, tid) || return none
    jobs = log[tid]
    count = jobcount(jobs, t)
    count > 0 || return none
    jobstr = string(jobactive(jobs, t).id)
    return string(_pad(width-2-length(jobstr)), count > 1 ? "*" : " ", jobstr, " ")
end


"""
    ThreadPools.showactivity([io, ]log, dt, t0=0, t1=Inf; nthreads=Threads.nthreads())

Produces a textual graph of the thread activity in the provided log.

The format of the output is

```julia
julia> ThreadPools.showactivity("mylog.txt", 0.1)
0.000   -   -   -   -
0.100   4   2   1   3
0.200   4   2   5   3
0.300   4   6   5   3
0.400   4   6   5   7
0.500   8   6   5   7
0.600   8   6   5   7
0.700   8   6   -   7
0.800   8   6   -   7
0.900   8   -   -   7
1.000   8   -   -   7
1.100   8   -   -   -
1.200   8   -   -   -
1.300   -   -   -   -
1.400   -   -   -   -
```
where the first column is time, and each column afterwards is the active job
id in each thread (threads 1:nthreads, left to right) at that point in
time.

If `io` is provided, the output will be written there.  `log` may be a log IO 
object, or a filename to be opened and read.  `dt` is the time step
for each row, `t0` is the optional starting time, `t1` the optional stopping 
time, and `nthreads` is the number of threads to print.
"""
function showactivity(io, log::Dict{Int, Vector{Job}}, dt, t0=0, t1=Inf; nthreads=0)
    maxj = maximum(j.id for jobs in values(log) for j in jobs)
    width = length(string(maxj)) + 3

    maxt = maximum(duration(x) for x in values(log))
    t1 = min(t1, (ceil(maxt/dt)+2)*dt)

    t = floor(t0/dt)*dt
    nonecnt = 0
    nthreads = nthreads == 0 ? Threads.nthreads() : nthreads
    while t <= t1
        tstr = @sprintf "%0.3f" t
        println(io, "$tstr $(string([_formatjob(log, tid, t, width) for tid in 1:nthreads]...))")
        t += dt
    end
end

showactivity(io, fname::String, dt, t0=0, t1=Inf; nthreads=0) = showactivity(io, readlog(fname), dt, t0, t1; nthreads=nthreads)
showactivity(log::Dict{Int, Vector{Job}}, dt, t0=0, t1=Inf; nthreads=0) = showactivity(Base.stdout, log, dt, t0, t1; nthreads=nthreads)
showactivity(fname::String, dt, t0=0, t1=Inf; nthreads=0) = showactivity(Base.stdout, readlog(fname), dt, t0, t1; nthreads=nthreads)
