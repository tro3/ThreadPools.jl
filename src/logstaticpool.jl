
#############################
# Internal Structures
#############################

struct LoggedStaticPool <: AbstractThreadPool
    tids :: Vector{Int}
    lck  :: ReentrantLock
    recs :: Vector{ThreadRecord}
    t0   :: UInt64
    log  :: ThreadLog
end


#############################
# Constructors / Finalizer
#############################

"""
    LoggedStaticPool(init_thrd=1, nthrds=Threads.nthreads())

The main LoggedStaticPool object.
"""
function LoggedStaticPool(init_thrd::Integer=1, nthrds::Integer=Threads.nthreads())
    thrd0 = min(init_thrd, Threads.nthreads())
    thrd1 = min(thrd0+nthrds-1, Threads.nthreads())
    return LoggedStaticPool(thrd0:thrd1, ReentrantLock(), ThreadRecord[], time_ns(), ThreadLog())
end


function Base.close(pool::LoggedStaticPool)
    _recordstolog!(pool.log, pool.recs, pool. t0)
end


#############################
# ThreadPool Interface
#############################

function tmap(pool::LoggedStaticPool, fn::Function, itr)
    data = collect(itr)
    applicable(fn, data[1]) || error("function can't be applied to iterator contents")
    N = length(data)
    sizehint!(pool.recs, N)
    result = Array{_detect_type(fn, data), ndims(data)}(undef, size(data))
    nthrds = length(pool.tids)
    njobs = div(N,nthrds)
    remjobs = N % nthrds

    len(ind) = max(0, njobs + (nthrds-ind+1 <= remjobs ? 1 : 0))
    finish(ind) = sum([len(x) for x in 1:ind])
    start(ind) = finish(ind)-len(ind)+1

    _fn(ind) = begin
        if finish(ind) > 0
            tid = Threads.threadid()
            for i in start(ind):finish(ind)
                lock(pool.lck)
                push!(pool.recs, (i, tid, true, time_ns()))
                unlock(pool.lck)
                @inbounds result[i] = fn(Base.unsafe_getindex(data, i))
                lock(pool.lck)
                push!(pool.recs, (i, tid, false, time_ns()))
                unlock(pool.lck)
            end
        end
    end

    Threads.@threads for tid in 1:Threads.nthreads()
        ind = findfirst(t->t==tid, pool.tids)
        isnothing(ind) || _fn(ind)
    end

    return result
end
