
import Printf: @sprintf
import Statistics: mean
#import Plots: plot
using RecipesBase

const ThreadRecord = Tuple{Int, Int, Bool, UInt64} #Jobnum, Thread ID, ?Start:Stop, Time

struct Job
    id    :: Int
    tid   :: Int
    start :: Int 
    stop  :: Int
end

const ThreadLog = Dict{Int, Vector{Job}}


duration(job::Job) = job.stop - job.start
active(job::Job, t) = t >= job.start && t < job.stop

duration(jobs::Vector{Job}) = maximum(j.stop for j in jobs) - minimum(j.start for j in jobs) # Nonoptimized
jobcount(jobs::Vector{Job}, t) = length(filter(j -> active(j,t), jobs))
jobactive(jobs::Vector{Job}, t) = first(filter(j -> active(j,t), jobs))
gaptime(jobs::Vector{Job}) = sum(y.start - x.stop for (x,y) in zip(jobs[1:end-1], jobs[2:end]))


function _recordstolog!(log::ThreadLog, records::Vector{ThreadRecord}, t0 = 0)
    starts = Dict{Int, Float64}()
    for (i, (id, tid, start, t)) in enumerate(records)
        if start
            starts[id] = t
        else
            haskey(starts, id) || error("Stop encountered before start: record $i, job id $id")
            push!(get!(log, tid, Job[]), Job(id, tid, starts[id]-t0, t-t0))
        end
    end
    for jobs in values(log)
        sort!(jobs, by=x->x.id)
    end
    return log
end

_recordstolog(records, t0) = _recordstolog!(ThreadLog(), records, t0)



"""
    ThreadPools.dumplog(io, log)

"""

function dumplog(io::IO, log::ThreadLog)
    for job in Iterators.flatten(values(log))
        write(io, "$(job.id) $(job.tid) $(job.start) $(job.stop)\n")
    end
    close(io)
end

dumplog(fname::String, log::ThreadLog) = dumplog(open(fname, "w"), log)
dumplog(io, pool::AbstractThreadPool) = dumplog(io, pool.log)



"""
    ThreadPools.readlog(io) -> Dict of (thread # => job list)

Analyzes the output of a [`LoggedThreadPool`](@ref) and produces the history
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
    log = ThreadLog()
    job = 0
    tid = 0
    start = 0.0
    stop = 0.0
    for (i,line) in enumerate(readlines(io))
        try
            (a,b,c,d) = split(line)
            job   = parse(Int, a)
            tid   = parse(Int, b)
            start = parse(Int, c)
            stop  = parse(Int, d)
        catch
            error("Malformed log entry, line $i: $line")
        end
        push!(get!(log, tid, Job[]), Job(job, tid, start, stop))
    end
    close(io)
    return log
end

readlog(fname::String) = readlog(open(fname))



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

_tons(x) = Int(round(x/1e-9))

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
function showactivity(io, log::ThreadLog, dt, t0=0, t1=Inf; nthreads=0)
    maxj = maximum(j.id for jobs in values(log) for j in jobs)
    width = length(string(maxj)) + 3

    maxt = maximum(duration(x) for x in values(log))
    dtns = _tons(dt)
    t0ns = _tons(t0)
    t1ns = min(t1==Inf ? typemax(Int64) : _tons(t1), (ceil(maxt/dtns)+2)*dtns)
    tns = (t0ns ÷ dtns)*dtns

    nthreads = nthreads == 0 ? Threads.nthreads() : nthreads
    
    # t = floor(t0/dt)*dt
    # tns  = Int(round(t/1e-9))
    # t0ns = Int(round(t0/1e-9))
    # t1ns = Int(round(t1/1e-9))
    # dtns = Int(round(dt/1e-9))
    # println((tns, t0ns, t1ns, dtns))
    while tns <= t1ns
        tstr = @sprintf "%0.3f" (tns*1e-9)
        println(io, "$tstr $(string([_formatjob(log, tid, tns, width) for tid in 1:nthreads]...))")
        tns += dtns
    end
end

showactivity(io, fname::String, dt, t0=0, t1=Inf; nthreads=0) = showactivity(io, readlog(fname), dt, t0, t1; nthreads=nthreads)
showactivity(log::ThreadLog, dt, t0=0, t1=Inf; nthreads=0) = showactivity(Base.stdout, log, dt, t0, t1; nthreads=nthreads)
showactivity(fname::String, dt, t0=0, t1=Inf; nthreads=0) = showactivity(Base.stdout, readlog(fname), dt, t0, t1; nthreads=nthreads)
showactivity(io, pool::AbstractThreadPool, dt, t0=0, t1=Inf; nthreads=0) = showactivity(io, pool.log, dt, t0, t1; nthreads=nthreads)
showactivity(pool::AbstractThreadPool, dt, t0=0, t1=Inf; nthreads=0) = showactivity(Base.stdout, pool.log, dt, t0, t1; nthreads=nthreads)


"""
    ThreadPools.showstats([io, ]log)

Produces a statistical analysis of the provided log.

# Example
```julia
julia> ThreadPools.showstats("mylog.txt")

    Total duration: 1.542 s
    Number of jobs: 8
    Average job duration: 0.462 s
    Minimum job duration: 0.111 s
    Maximum job duration: 0.82 s

    Thread 2: Duration 1.542 s, Gap time 0.0 s
    Thread 3: Duration 1.23 s, Gap time 0.0 s
    Thread 4: Duration 0.925 s, Gap time 0.0 s

```
"""
function showstats(io, log::Dict{Int, Vector{Job}})
    flat = collect(Iterators.flatten(jobs for jobs in values(log)))
    totduration = duration(flat)*1e-9
    durations = [duration(job)*1e-9 for job in flat]
    print(io, """

    Total duration: $(round(totduration; digits=3)) s
    Number of jobs: $(length(flat))
    Average job duration: $(round(mean(durations); digits=3)) s
    Minimum job duration: $(round(minimum(durations); digits=3)) s
    Maximum job duration: $(round(maximum(durations); digits=3)) s

""")
    for thrd in sort!(collect(keys(log)))
        dur = round(duration(log[thrd])*1e-9; digits=3)
        gap = round(gaptime(log[thrd])*1e-9; digits=3)
        println(io, "    Thread $thrd: Duration $dur s, Gap time $gap s")
    end
end

showstats(io, fname::String) = showstats(io, readlog(fname))
showstats(log::Dict{Int, Vector{Job}}) = showstats(Base.stdout, log)
showstats(fname::String) = showstats(Base.stdout, readlog(fname))


"""
    plot(log)
    plot(pool)

Produces a plot of the activity across the threads.  `log` can be 
the output of `readlog` or a string representing the log file name.
"""
@recipe function f(log::ThreadLog)
    ids, threadids, starts, stops = _get_plot_data(log)

    seriescolor   --> [threadids threadids]'
    xguide  --> "Time [s]"
    yguide  --> "Job Index"
    legend  --> false

    [starts stops]',  [ids ids]'
end

@recipe function f(pool::AbstractThreadPool)
    log = pool.log
    ids, threadids, starts, stops = _get_plot_data(log)

    seriescolor   --> [threadids threadids]'
    xguide  --> "Time [s]"
    yguide  --> "Job Index"
    legend  --> false

    [starts stops]',  [ids ids]'
end

function _get_plot_data(log::ThreadLog)
    jobs = collect(Iterators.flatten(jobs for jobs in values(log)))
    t0 = minimum(j.start for j in jobs)
    sort!(jobs, by=j->j.id)
    ids = [j.id for j in jobs]
    starts = [(j.start-t0)/1e9 for j in jobs]
    stops = [(j.stop-t0)/1e9 for j in jobs]
    threadids = [j.tid for j in jobs]

    return ids, threadids, starts, stops
end