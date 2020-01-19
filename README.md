# ThreadPools.jl

_Improved thread management for background and nonuniform tasks_

A simple package that creates a few functions mimicked from `Base`
([`bgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgforeach-Tuple{Any,Any}), 
[`bgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgmap-Tuple{Any,Any}),
and
[`@bgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@bgthreads))
that behave like the originals but generate spawned tasks 
that stay purely on background threads.  For better throughput for more
uniform tasks, primary thread versions are also provided, and logging 
versions of all of the above are included for tuning purposes.

Documentation at https://tro3.github.io/ThreadPools.jl

## Overview

As of v1.3.1, Julia does not have any built-in mechanisms for keeping 
computational threads off of the primary thread.  For many use cases, this 
restriction is not important - usually, pure computational activities will 
run faster using all threads.  But in some cases, we may want to keep the 
primary thread free of blocking tasks.  For example, a GUI running on the 
primary thread will become unresponsive if a computational task hits.  For 
another, parallel computations with very nonuniform processing times can 
benefit from sacrificing the primary thread to manage the loads on the 
remaining ones.

ThreadPool is a simple package that allows background-only Task assignment for 
cases where this makes sense.  As Julia matures, it is hoped this package is 
made obsolete.  The standard `foreach`,  `map`, and `@threads` functions are 
mimicked, adding a `bg` prefix to each to denote background operation: 
[`bgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgforeach-Tuple{Any,Any}), 
[`bgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgmap-Tuple{Any,Any}),
and
[`@bgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@bgthreads).
Code that runs with one of those Base functions will run the same with the 
`bg` prepended, but adding multithreading for free in the `foreach` and `map` 
cases, and in all cases keeping the primary thread free of blocking Tasks.

Foreground versions, 
[`fgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgforeach-Tuple{Any,Any}), 
[`fgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgmap-Tuple{Any,Any}),
and
[`@fgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@fgthreads)
are also included for cases where the work tasks are a little more uniform, so
that the primary thread impact does not reduce throughput.  Finally, there are
logging versions of each of the above commands
[`logbgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.logbgforeach), 
[`logbgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.logbgmap), 
etc, as well as some analysis utilities to help in tuning performance.


## Usage

Each of the simple API functions can be used like the `Base` versions of the 
same function, with a `bg` prepended to the function: 

```julia
julia> bgforeach([1,2,3]) do x
         println("$(x+1) $(Threads.threadid())")
       end
3 3
4 4
2 2

julia> bgmap([1,2,3]) do x
         println("$x $(Threads.threadid())")
         x^2
       end
2 3
3 4
1 2
3-element Array{Int64,1}:
 1
 4
 9

julia> @bgthreads for x in 1:3
         println("$x $(Threads.threadid())")
       end
2 3
3 4
1 2
```
For an example of a more complex load-management scenario, see 
`examples/stackdemo.jl`.


## Logger Usage

The logging versions of the functions take in an IO as the log, or and string
that will cause a new file to be created and used by the log.  The 
[`readlog`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.readlog)
and 
[`showactivity`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.showactivity)
functions help visualize the activity (here, a 4-thread system using the primary with `fgforeach`):

```julia
julia> ThreadPools.logfgforeach(x -> sleep(0.1*x), "log.txt", 1:8)

julia> log = ThreadPools.readlog("log.txt")
Dict{Int64,Array{ThreadPools.Job,1}} with 4 entries:
  4 => ThreadPools.Job[Job(3, 4, 0.0149999, 0.343), Job(7, 4, 0.343, 1.045)]
  2 => ThreadPools.Job[Job(2, 2, 0.0149999, 0.249), Job(6, 2, 0.249, 0.851)]
  3 => ThreadPools.Job[Job(1, 3, 0.0149999, 0.14), Job(5, 3, 0.14, 0.641)]
  1 => ThreadPools.Job[Job(4, 1, 0.0149999, 0.44), Job(8, 1, 0.44, 1.241)]

julia> ThreadPools.showactivity(log, 0.1)
0.000   -   -   -   -
0.100   4   2   1   3
0.200   4   2   5   3
0.300   4   6   5   3
0.400   4   6   5   7
0.500   8   6   5   7
0.600   8   6   5   7
0.700   8   6   -   7
0.800   8   6   -   7
0.900   8   -   -   7
1.000   8   -   -   7
1.100   8   -   -   -
1.200   8   -   -   -
1.300   -   -   -   -
1.400   -   -   -   -
```
