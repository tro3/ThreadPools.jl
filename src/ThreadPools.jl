module ThreadPools

export @tthreads, @bthreads, @qthreads, @qbthreads
export @logthreads, @logbthreads, @logqthreads, @logqbthreads
export twith, poolresults, isactive, @tspawnat
export dumplog, readlog, showactivity, showstats
export tmap, bmap, qmap, qbmap
export logtmap, logbmap, logqmap, logqbmap
export tforeach, bforeach, qforeach, qbforeach
export logtforeach, logbforeach, logqforeach, logqbforeach

include("interface.jl")
include("macros.jl")
include("logs.jl")
include("staticpool.jl")
include("qpool.jl")
include("logstaticpool.jl")
include("logqpool.jl")
include("simplefuncs.jl")


export @pthreads, pwith

@deprecate tforeach(pool::AbstractThreadPool, fn, itrs...) tforeach(fn, pool, itrs...)
@deprecate tmap(pool::AbstractThreadPool, fn, itrs...) tmap(fn, pool, itrs...)
@deprecate pwith(fn, pool) twith(fn, pool)

macro pthreads(thrdid, expr)
    @warn "`@pthreads` is deprecated, use `tthreads` instead."
end


end # module
