
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

function tmap(pool::StaticPool, fn::Function, itr)
    N = length(itr)
    result = Vector{_detect_type(fn, itr)}(undef, N)
    nts = length(pool.tids)
    n = div(N,nts)
    r = N % nts

    _fn = (tind) -> begin
        n0 = (tind-1)*n + 1 + (nts-tind+1 > r ? 0 : tind-nts+1)
        n1 = n0-1 + n + (nts-tind+1 <= r ? 1 : 0)
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

#