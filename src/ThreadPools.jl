module ThreadPools

export @bthreads, @qthreads, @qbthreads
export @logthreads, @logbthreads, @logqthreads, @logqbthreads
export pwith, @pthreads, results, isactive, @tspawnat
export dumplog, readlog, showactivity, showstats
export tmap, bmap, qmap, qbmap
export logtmap, logbmap, logqmap, logqbmap
export tforeach, bforeach, qforeach, qbforeach
export logtforeach, logbforeach, logqforeach, logqbforeach

include("interface.jl")
include("logs.jl")
include("staticpool.jl")
include("qpool.jl")
include("logstaticpool.jl")
include("logqpool.jl")
include("macros.jl")
include("simplefuncs.jl")

end # module
