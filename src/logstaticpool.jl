
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

function tmap(pool::LoggedStaticPool, fn::Function, itr)::Vector{_detect_type(fn, itr)}
    N = length(itr)
    sizehint!(pool.recs, N)
    result = Vector{_detect_type(fn, itr)}(undef, N)
    nts = length(pool.tids)
    n = div(N,nts)
    r = N % nts

    _fn = (tind) -> begin
        n0 = (tind-1)*n + 1 + (nts-tind+1 > r ? 0 : tind-nts+1)
        n1 = n0-1 + n + (nts-tind+1 <= r ? 1 : 0)
        tid = Threads.threadid()
        for i in n0:n1
            lock(pool.lck)
            push!(pool.recs, (i, tid, true, time_ns()))
            unlock(pool.lck)
            @inbounds result[i] = fn(Base.unsafe_getindex(itr, i))
            lock(pool.lck)
            push!(pool.recs, (i, tid, false, time_ns()))
            unlock(pool.lck)
        end
    end

    Threads.@threads for tid in 1:Threads.nthreads()
        ind = findfirst(t->t==tid, pool.tids)
        isnothing(ind) || _fn(ind)
    end

    return result
end
