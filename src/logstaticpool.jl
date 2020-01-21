
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
    LoggedStaticPool(thrd0=1, nthrds=Threads.nthreads())

The main LoggedStaticPool object.
"""
function LoggedStaticPool(thrd0::Integer=1, nthrds::Integer=Threads.nthreads())
    thrd0 = min(thrd0, Threads.nthreads())
    thrd1 = min(thrd0+nthrds-1, Threads.nthreads())
    return LoggedStaticPool(thrd0:thrd1, ReentrantLock(), ThreadRecord[], time_ns(), ThreadLog())
end


"""
    Base.close(pool::LoggedStaticPool)


"""
function Base.close(pool::LoggedStaticPool)
    _recordstolog!(pool.log, pool.recs, pool. t0)
end


#############################
# ThreadPool Interface
#############################

function pmap(pool::LoggedStaticPool, fn::Function, itr)::Vector{_detect_type(fn, itr)}
    N = length(itr)
    sizehint!(pool.recs, N)
    result = Vector{_detect_type(fn, itr)}(undef, N)
    nts = length(pool.tids)
    n = div(N,nts) + (N % nts > 0 ? 1 : 0)

    _fn = (tind) -> begin
        n0 = (tind-1)*n + 1
        n1 = tind == nts ? N : tind*n
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
