module ThreadPools

export @bthreads, @qthreads, @qbthreads
export @logthreads, @logbthreads, @logqthreads, @logqbthreads
export pforeach, pmap, pwith, @pthreads, results
export dumplog, readlog, showactivity, showstats

include("interface.jl")
include("logs.jl")
include("staticpool.jl")
include("qpool.jl")
include("logstaticpool.jl")
include("logqpool.jl")
include("macros.jl")

end # module
