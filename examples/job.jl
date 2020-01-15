using Printf


# Job Definitions

struct Job
    thread :: Int
    jobnum :: Int
    start  :: Float64
    stop   :: Float64
end

function work(jobnum, jobtime, t0)
    tinit = time()
    endtime = tinit + jobtime
    while time() < endtime  # Intentionally blocking
        nothing
    end
    return Job(Threads.threadid(), jobnum, tinit-t0, time()-t0)
end


# Analysis Functions

function sortbythread(jobs)
    threads = Dict([x => [] for x in 1:Threads.nthreads()])
    for job in jobs
        push!(threads[job.thread], job)
    end
    return [threads[x] for x in 1:Threads.nthreads()]
end

function threads_busy(jobs)
    sorted = sortbythread(jobs)
    return [isempty(thread) ? nothing : (minimum(x.start for x in thread), maximum(x.stop for x in thread)) for thread in sorted]
end

function job_distribution(jobs)
    sorted = sortbythread(jobs)
    return [length(x) for x in sorted]
end

function job_active(jobs, time)
    for job in jobs
        if job.start < time && job.stop > time
            return job.jobnum
        end
    end
    return 0
end

function duration(jobs)
    return maximum(x.stop for x in jobs)
end

function show_activity(jobs)
    sorted = sortbythread(jobs)
    stoptime = ceil(maximum(x.stop for x in jobs))
    for thread in sorted
        for t in 0.0:0.2:stoptime
            str = @sprintf("%4d", job_active(thread, t))
            print(str)
        end
        print("\n")
    end
end