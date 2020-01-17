module ThreadPools

export bgforeach, bgmap, @bgthreads
export fgforeach, fgmap, @fgthreads
export ThreadPool, isactive, results

include("pool.jl")
include("logpool.jl")
include("functions.jl")

end # module
