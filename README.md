# ThreadPools.jl

_Improved thread management for nonuniform tasks_

A simple package that creates a few functions mimicked from `Base`
([`bgforeach`](https://tro3.github.io/ThreadPool.jl/build/index.html#ThreadPool.bgforeach-Tuple{Any,Any}), 
[`bgmap`](https://tro3.github.io/ThreadPool.jl/build/index.html#ThreadPool.bgmap-Tuple{Any,Any}),
and
[`@bgthreads`](https://tro3.github.io/ThreadPool.jl/build/index.html#ThreadPool.@bgthreads))
that behave like the originals but generate spawned tasks 
that stay purely on background threads.

Documentation at https://tro3.github.io/ThreadPools.jl

## Overview

As of v1.3.1, Julia does not have any built-in mechanisms for keeping 
computational threads off of the primary thread.  For many use cases, this 
restriction is not important - except in very specific instances, pure 
computational activities will run faster using all threads.  But in some cases, 
we may want to keep the primary thread free of blocking tasks.  For example, a 
GUI running on the primary thread will become unresponsive if a computational 
task hits.  For another, parallel computations with very nonuniform processing
times can benefit from sacrificing the primary thread to manage the loads on
the remaining ones.

ThreadPool is a simple package that allows background-only Task assignment for 
cases where this makes sense.  As Julia matures, it is hoped this package is 
made obsolete.  The standard `foreach`,  `map`, and `@threads` functions are 
mimicked, adding a `bg` prefix to each to denote background operation: 
[`bgforeach`](@ref), [`bgmap`](@ref), [`@bgthreads`](@ref).  Code that runs 
with one of  those Base functions should run just fine with the `bg` prepended, 
but adding multithreading for free  in the `foreach` and `map` cases, and in 
all cases keeping the primary thread free of blocking Tasks.

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
