
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

    Threads.@threads for tid in 1:Threads.nthreads()
        ind = findfirst(t->t==tid, pool.tids)
        isnothing(ind) || _fn(ind)
    end

    return result
end
