module ThreadPools

export bgforeach, bgmap, @bgthreads, ThreadPool, isactive

include("pool.jl")
include("functions.jl")

end # module
