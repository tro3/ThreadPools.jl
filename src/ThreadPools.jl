module ThreadPools

export bgforeach, bgmap, @bgthreads
export fgforeach, fgmap, @fgthreads
export ThreadPool, isactive

include("pool.jl")
include("functions.jl")

end # module
