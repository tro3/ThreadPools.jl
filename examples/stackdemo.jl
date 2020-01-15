module Demo

using ThreadPools

include("job.jl")


# Simulation Setup

struct WorkNode
    jobtime  :: Float64
    children :: Vector{WorkNode}
end

function stack_fn(jobnum, worknode, t0)
    job = work(jobnum, worknode.jobtime, t0)
    return job, worknode.children 
end

function gen_worknode!(distribution)
    node = WorkNode(pop!(distribution), [])
    rnd = rand()
    while rnd < 0.25 && length(distribution) > 0
        push!(node.children, gen_worknode!(distribution))
        rnd = rand()
    end
    return node
end

function gen_worknodes(distribution)
    stack = copy(distribution)
    result = []
    while length(stack) > 0
        push!(result, gen_worknode!(stack))
    end
    return result    
end


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
    stack1 = gen_worknodes(distribution)
    stack2 = deepcopy(stack1)
    N0 = length(stack1)

    jobs1 = Job[]
    t0 = time()
    pool = ThreadPool()
    lck = ReentrantLock()
    index = 0

    running = true
    @async begin
        while running
            node = nothing
            lock(lck)
            length(stack1) > 0 && (node = pop!(stack1))
            unlock(lck)
            if isnothing(node)
                running = isactive(pool)
            else
                index += 1
                put!(pool, stack_fn, index, node, t0)
            end
            sleep(1e-4)
            yield()
        end
        close(pool)
    end

    for task in pool
        job, newjobs = fetch(task)
        push!(jobs1, job)
        lock(lck)
        append!(stack1, newjobs)
        unlock(lck)
        sleep(1e-4)
        yield()
    end


    println("\n\n@bgthreads, Active Job Per Thread on 200ms Intervals\n")
    show_activity(jobs1)


    tasks = Channel{Task}(Inf)
    jobs2 = Job[]
    t0 = time()
    index = 0
    while length(stack2) > 0
        N = length(stack2)
        @async begin
            lock(lck)
            Threads.@threads for node in stack2
                index += 1
                let
                    i = index
                    n = node
                    t = t0
                    put!(tasks, Threads.@spawn stack_fn(i,n,t))
                end
            end
            empty!(stack2)
            unlock(lck)
        end

        for i in 1:N
            task = take!(tasks)
            job, newjobs = fetch(task)
            push!(jobs2, job)
            lock(lck)
            append!(stack2, newjobs)
            unlock(lck)
        end
    end

    println("\n\n@threads, Active Job Per Thread on 200ms Intervals\n")
    show_activity(jobs2)

    eff = round(100*(duration(jobs1)/duration(jobs2)-1), digits=1)
    exp = round(100*(Threads.nthreads()/(Threads.nthreads()-1)-1), digits=1)
    println("\nSpeed increase using all threads (ideal $exp%): $eff%")    
end

end
