# ThreadPools.jl

_Improved thread management for background and nonuniform tasks_

A simple package that exposes a couple of macros that mimic 
`Base.Threads.@threads`:
[`@fgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@fgthreads)
and
[`@bgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@bgthreads).  
Both macros use active thread management to keep all threads busy, even when 
processing tasks with varying durations.  The `@fgthreads` uses all available 
threads, while `@bgthreads` version keeps the tasks in the background.  There
are also version of the `Base.map` and `Base.foreach` functions that behave 
similarly:
[`fgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgmap-Tuple{Any,Any}),
[`bgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgmap-Tuple{Any,Any}),
[`fgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgforeach-Tuple{Any,Any}), 
and
[`bgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgforeach-Tuple{Any,Any}), 
as well as logging versions of all of the above and the original `@threads` 
macro for tuning purposes.

Documentation at https://tro3.github.io/ThreadPools.jl

## Overview

As of Julia 1.3, the algorithm of the `@threads` macro is to pre-divide the 
incoming range into equal partitions running on each thread.  This is very 
efficient for most use cases, but there are a couple of scenarios where
this can present a problem:

* When something else is running on the primary thread, like a GUI or a web 
  server
* When the tasks are very nonuniform, possibly leading to one thread working
  on the longer tasks while the others sit idle

ThreadPools is a simple package that exposes foreground and background variants
of `@threads`, `map`, and `foreach` that actively manage the threads, starting 
a new task when the previous one completes and in the case of the background 
versions, keeping them off the primary thread.  The foreground versions are
prepended with `fg` and background with `bg`, leading to:

* [`@fgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@fgthreads)
* [`@bgthreads`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.@bgthreads)
* [`fgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgmap-Tuple{Any,Any})
* [`bgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgmap-Tuple{Any,Any})
* [`fgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgforeach-Tuple{Any,Any})
* [`bgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.bgforeach-Tuple{Any,Any})

There are also versions of the above functions that will produce a task log to 
help tune performance.  These are prepended with a `log` (for example,
[`logbgmap`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.logbgmap)
).  There are also a logging version of `Base.Threads.@threads` to compare with 
and some analysis utilities included.


## Usage

Each of the simple API functions can be used like the `Base` versions of the 
same function: 

```julia
julia> @bgthreads for x in 1:3
         println("$x $(Threads.threadid())")
       end
2 3
3 4
1 2

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
```
Note that while the execution order is not guaranteed across threads, but the 
result of `bgmap` will of course match the input. For an example 
of a more complex load-management scenario, see `examples/stackdemo.jl`.


## Logger Usage

The logging versions of the functions take either an IO for the log or a 
filename to be created and used as the log.  The 
[`readlog`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.readlog), 
[`showstats`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.showstats), 
and 
[`showactivity`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.showactivity) 
functions help visualize 
the activity  (here, a 4-thread system using the primary with 
[`fgforeach`](https://tro3.github.io/ThreadPools.jl/build/index.html#ThreadPools.fgforeach-Tuple{Any,Any})):

```julia
julia> ThreadPools.logfgforeach(x -> sleep(0.1*x), "log.txt", 1:8)

julia> log = ThreadPools.readlog("log.txt")
Dict{Int64,Array{ThreadPools.Job,1}} with 4 entries:
  4 => ThreadPools.Job[Job(3, 4, 0.016, 0.328), Job(7, 4, 0.328, 1.039)]
  2 => ThreadPools.Job[Job(2, 2, 0.016, 0.228), Job(6, 2, 0.228, 0.843)]
  3 => ThreadPools.Job[Job(1, 3, 0.016, 0.128), Job(5, 3, 0.128, 0.629)]
  1 => ThreadPools.Job[Job(4, 1, 0.016, 0.428), Job(8, 1, 0.428, 1.233)]

julia> ThreadPools.showstats(log)

    Total duration: 1.217 s
    Number of jobs: 8
    Average job duration: 0.46 s
    Minimum job duration: 0.112 s
    Maximum job duration: 0.805 s

    Thread 1: Duration 1.217 s, Gap time 0.0 s
    Thread 2: Duration 0.827 s, Gap time 0.0 s
    Thread 3: Duration 0.613 s, Gap time 0.0 s
    Thread 4: Duration 1.023 s, Gap time 0.0 s

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
