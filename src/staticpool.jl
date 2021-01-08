
#############################
# Internal Structures
#############################

struct StaticPool <: AbstractThreadPool
    tids :: Vector{Int}
end



#############################
# Constructors
#############################

"""
    StaticPool(init_thrd=1, nthrds=Threads.nthreads())

The main StaticPool object.   
"""
function StaticPool(init_thrd::Integer=1, nthrds::Integer=Threads.nthreads())
    thrd0 = min(init_thrd, Threads.nthreads())
    thrd1 = min(init_thrd+nthrds-1, Threads.nthreads())
    return StaticPool(thrd0:thrd1)
end



#############################
# ThreadPool Interface
#############################

function tmap(fn, pool::StaticPool, itr)
    data = collect(itr)
    applicable(fn, first(data)) || error("function can't be applied to iterator contents")
    N = length(data)
    result = Array{_detect_type(fn, data), ndims(data)}(undef, size(data))
    nthrds = length(pool.tids)
    njobs = div(N,nthrds)
    remjobs = N % nthrds

    len(ind) = max(0, njobs + (nthrds-ind+1 <= remjobs ? 1 : 0))
    finish(ind) = sum([len(x) for x in 1:ind])
    start(ind) = finish(ind)-len(ind)+1

    _fn(ind) = begin
        if finish(ind) > 0
            for i in start(ind):finish(ind)
                @inbounds result[i] = fn(Base.unsafe_getindex(data, i))
            end
        end
    end

    tasks = Channel(Inf)
    for tid in 1:Threads.nthreads()
        ind = findfirst(t->t==tid, pool.tids)
        if !isnothing(ind)
            task = @tspawnat tid _fn(ind)
            put!(tasks, task)
        end
    end
    _sync_end(tasks)

    return result
end


# From Julia PR #39007
function _schedule_result(t, rs)
    schedule(Task(() -> begin
        ex = nothing
        try
            wait(t)
        catch e
            ex = e
        finally
            put!(rs, ex)
        end
    end))
end

# Modified from Julia PR #39007 to duplicate error handling of tmap
function _sync_end(c::Channel{Any})
    try
        n = 0
        isready(c) || return
        while true
            t = take!(c)
            if t isa Exception
                while isready(c)                       # Clean the channel
                    take!(c)
                end
                throw(t)
            elseif isnothing(t)                        # Successful result from monitor.
                n -= 1                                 # Leave if nothing remains.
                n == 0 && !isready(c) && break
            else                                       # Not a monitor result - must be
                n += 1                                 # a new waitable. Create a new
                _schedule_result(t, c)                 # monitor and return to Channel
            end
        end
    finally
        close(c)
    end
    nothing
end