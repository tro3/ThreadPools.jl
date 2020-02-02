module ThreadPools

export @bthreads, @qthreads, @qbthreads
export @logthreads, @logbthreads, @logqthreads, @logqbthreads
export pwith, @pthreads, results, isactive, @pspawnat
export dumplog, readlog, showactivity, showstats
export pmap, bmap, qmap, qbmap
export logpmap, logbmap, logqmap, logqbmap
export pforeach, bforeach, qforeach, qbforeach
export logpforeach, logbforeach, logqforeach, logqbforeach

include("interface.jl")
include("logs.jl")
include("staticpool.jl")
include("qpool.jl")
include("logstaticpool.jl")
include("logqpool.jl")
include("macros.jl")
include("simplefuncs.jl")

end # module
