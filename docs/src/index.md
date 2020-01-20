
# ThreadPools.jl Documentation

_Improved thread management for background and nonuniform tasks_

A simple package that exposes a couple of macros that mimic 
`Base.Threads.@threads`:
[`@fgthreads`](@ref)
and
[`@bgthreads`](@ref).  
Both macros use active thread management to keep all threads busy, even when 
processing tasks with varying durations.  The `@fgthreads` uses all available 
threads, while `@bgthreads` version keeps the tasks in the background.  There
are also version of the `Base.map` and `Base.foreach` functions that behave 
similarly:
[`fgmap`](@ref),
[`bgmap`](@ref),
[`fgforeach`](@ref), 
and
[`bgforeach`](@ref), 
as well as logging versions of all of the above and the original
`@threads` macro for tuning purposes.

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
filename to be created and used as the log.  The `readlog`, 
`showstats`, and `showactivity` functions help visualize 
the activity  (here, a 4-thread system using the primary with 
`fgforeach`:

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

## Demonstrations

There are a couple of demonstrations in the `examples` directory.  `demo.jl` 
shows how jobs are distributed across threads in both the `@threads` and 
`@bgthreads` cases for various workload distributions.  Running these demos 
is fairly simple (results below on 4 threads):

```
julia> include("examples/demo.jl")
Main.Demo

julia> Demo.run_with_outliers()


@bgthreads, Active Job Per Thread on 200ms Intervals

   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
   0   6  14  25  29  31  31  40  49  52  62  68  73  83  89   0 100 105 109 109 109 109 109 109 132 137 141 147   0   0   0
   0   8  15  20  30  33  33  33  50  57  63  66  66  84  90  94   0 104 108 112 116 121 123 127 131 134 134 134   0   0   0
   0   9  12  24  24  24  35  38   0  56  61  69   0  82  91  95  98  98  98 113 117 120 120 120 120 135 142 146   0   0   0


@threads, Active Job Per Thread on 200ms Intervals

   0   4   6   9  10  12  15  16  20  24  24  24  28  29  31  31  32  33  33  34  37   0   0   0   0   0
   0  43  46  50  52  54  56  60  62  65  66  66  68  70  73   0   0   0   0   0   0   0   0   0   0   0
   0  79  82  84  87  90  92  94  96  98  98  98  98 100 101 104 106 108 109 109 109 109 109 110 112   0
   0 117 119 120 120 120 120 121 124 127 131 133 134 134 134 137 141 143 146 149   0   0   0   0   0   0

Speed increase using all threads (ideal 33.3%): 14.4%
```
These demos generate numbered jobs with a randomized work distribution that can 
be varied.  There are normal, uniform,  and uniform with 10% outliers of 10x 
distributions.  The activity graphs in these demos present time-sliced shapshots 
of the thread activities, showing which job number was active in that time 
slice.

The available demos are:

* `Demo.run_with_uniform()`
* `Demo.run_with_variation()`
* `Demo.run_with_outliers()`

There is also a more complex demo at `examples/stackdemo.jl`.  Here, the 
workload is heirarchal - each jobs produces a result and possibly more jobs. 
The primary thread in this case is used purely more managing the job stack.


## Simple API

Each function of the simple API tries to mimic an existing function in `Base` 
or `Base.Threads` to keep any code rework to a minimum.

* [`bgforeach(fn, itr)`](@ref)
* [`bgmap(fn, itr)`](@ref)
* [`@bgthreads`](@ref)
* [`fgforeach(fn, itr)`](@ref)
* [`fgmap(fn, itr)`](@ref)
* [`@fgthreads`](@ref)

```@docs
bgforeach(fn, itr)
bgmap(fn, itr)
@bgthreads
fgforeach(fn, itr)
fgmap(fn, itr)
@fgthreads
```

# ThreadPool API

The [`ThreadPool`](#ThreadPools.ThreadPool) mimics the `Channel{Task}` API, 
where `put!`ting a `Task` causes it to be executed, and `take!` returns the 
completed `Task`.  The `ThreadPool` is iterable over the completed `Task`s
in the same way a `Channel` would be.

* [`ThreadPools.ThreadPool`](@ref)
* [`Base.put!(pool::ThreadPool, t::Task)`](#Base.put!(pool::ThreadPools.ThreadPool, t::Task))
* [`Base.put!(pool::ThreadPool, fn::Function, args...)`](#Base.put!(pool::ThreadPools.ThreadPool, fn::Function, args...))
* [`Base.take!(pool::ThreadPool, ind::Integer)`](#Base.take!(pool::ThreadPools.ThreadPool, ind::Integer))
* [`Base.close(pool::ThreadPool)`](#Base.close(pool::ThreadPools.ThreadPool))
* [`isactive(pool::ThreadPool)`](@ref)
* [`results(pool::ThreadPool)`](@ref)

```@docs
ThreadPools.ThreadPool
Base.put!(pool::ThreadPools.ThreadPool, t::Task)
Base.put!(pool::ThreadPools.ThreadPool, fn::Function, args...)
Base.take!(pool::ThreadPools.ThreadPool)
Base.close(pool::ThreadPools.ThreadPool)
isactive(pool::ThreadPool)
results(pool::ThreadPool)
```

# Logging API

For performance tuning, it can be useful to substitute in a logger that can be
used to analyze the thread activity.  `LoggingThreadPool` is provided for this
purpose.

* [`ThreadPools.logbgforeach`](@ref)
* [`ThreadPools.logbgmap`](@ref)
* [`ThreadPools.@logbgthreads`](@ref)
* [`ThreadPools.logfgforeach`](@ref)
* [`ThreadPools.logfgmap`](@ref)
* [`ThreadPools.@logfgthreads`](@ref)
* [`ThreadPools.@logthreads`](@ref)
* [`ThreadPools.readlog`](@ref)
* [`ThreadPools.showstats`](@ref)
* [`ThreadPools.showactivity`](@ref)
* [`ThreadPools.LoggingThreadPool`](@ref)

```@docs
ThreadPools.logbgforeach
ThreadPools.logbgmap
ThreadPools.@logbgthreads
ThreadPools.logfgforeach
ThreadPools.logfgmap
ThreadPools.@logfgthreads
ThreadPools.@logthreads io
ThreadPools.readlog
ThreadPools.showstats
ThreadPools.showactivity
ThreadPools.LoggingThreadPool
```
