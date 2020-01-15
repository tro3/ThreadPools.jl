module Demo


using ThreadPools

include("job.jl")


# Demo Functions

function run_with_uniform()
    N = 150 # Number of jobs
    T = 10  # Total test time
    run_demo([T/N for i in 1:N])
end

function run_with_variation()
    N = 150 # Number of jobs
    T = 10  # Total test time
    run_demo([T/N*(1+randn()) for i in 1:N])
end

function run_with_outliers()
    N = 150 # Number of jobs
    T = 10  # Total test time
    run_demo([rand() < 0.1 ? T/N*20*rand() : T/N*2*rand() for i in 1:N])
end


function run_demo(distribution)
    N = length(distribution)

    # Process with @bgthreads
    jobs1 = Union{Nothing, Job}[nothing for x in 1:N]
    t0 = time()
    @bgthreads for (jobnum, jobtime) in enumerate(distribution)
        jobs1[jobnum] = work(jobnum, jobtime, t0)
    end
    println("\n\n@bgthreads, Active Job Per Thread on 200ms Intervals\n")
    show_activity(jobs1)

    # Process with @fgthreads
    jobs2 = Union{Nothing, Job}[nothing for x in 1:N]
    t0 = time()
    @fgthreads for (jobnum, jobtime) in enumerate(distribution)
        jobs2[jobnum] = work(jobnum, jobtime, t0)
    end
    println("\n\n@fgthreads, Active Job Per Thread on 200ms Intervals\n")
    show_activity(jobs2)

    # Process with @threads
    jobs3 = Union{Nothing, Job}[nothing for x in 1:N]
    t0 = time()
    Threads.@threads for (jobnum, jobtime) in collect(enumerate(distribution))
        jobs3[jobnum] = work(jobnum, jobtime, t0)
    end
    println("\n\n@threads, Active Job Per Thread on 200ms Intervals\n")
    show_activity(jobs3)


    eff = round(100*(duration(jobs1)/duration(jobs2)-1), digits=1)
    exp = round(100*(Threads.nthreads()/(Threads.nthreads()-1)-1), digits=1)
    println("\nSpeed increase using @fgthreads (ideal $exp%): $eff%")

    eff = round(100*(duration(jobs1)/duration(jobs3)-1), digits=1)
    exp = round(100*(Threads.nthreads()/(Threads.nthreads()-1)-1), digits=1)
    println("\nSpeed increase using Threads.@threads (ideal $exp%): $eff%")
end


end
