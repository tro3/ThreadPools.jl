
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
    StaticPool(thrd0=1, nthrds=Threads.nthreads())

The main StaticPool object.   
"""
function StaticPool(thrd0::Integer=1, nthrds::Integer=Threads.nthreads())
    thrd0 = min(thrd0, Threads.nthreads())
    thrd1 = min(thrd0+nthrds-1, Threads.nthreads())
    return StaticPool(thrd0:thrd1)
end



#############################
# ThreadPool Interface
#############################

function pmap(pool::StaticPool, fn::Function, itr)
    N = length(itr)
    result = Vector{_detect_type(fn, itr)}(undef, N)
    nts = length(pool.tids)
    n = div(N,nts) + (N % nts > 0 ? 1 : 0)

    _fn = (tind) -> begin
        n0 = (tind-1)*n + 1
        n1 = tind == nts ? N : tind*n
        for i in n0:n1
            @inbounds result[i] = fn(Base.unsafe_getindex(itr, i))
        end
    end

    Threads.@threads for tid in 1:Threads.nthreads()
        ind = findfirst(t->t==tid, pool.tids)
        isnothing(ind) || _fn(ind)
    end

    return result
end
