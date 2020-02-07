# ThreadPools.jl

_Improved thread management for background and nonuniform tasks_

## Overview

Documentation at https://tro3.github.io/ThreadPools.jl

ThreadPools.jl is a simple package that exposes a few macros and functions
that mimic `Base.Threads.@threads`, `Base.map`, and `Base.foreach`. These 
macros (and the underlying API) handle cases that the built-in functions are 
not always well-suited for:

* A group of tasks that the user wants to keep off of the primary thread
* A group of tasks that are very nonuniform in duration

For the first case, ThreadPools exposes a `@bthreads` ("background threads") 
macro that behaves identically to `Threads.@threads`, but keeps the
primary thread job-free.  There are also related `bmap` and `bforeach`
functions that mimic their `Base` counterparts, but with the same non-primary 
thread usage.

For the second case, the package exposes a `@qthreads` ("queued threads") macro. 
This macro uses a different scheduling strategy to help with nonuniform jobs. 
`@threads` and `@bthreads` first divide the incoming job list into equal job 
"chunks", then launch each 
chunk on a separate thread for processing.  If the jobs are not uniform, this
can lead to some long jobs all getting assigned to one thread, delaying 
completion.  `@qthreads` does not pre-assign threads - it only starts a new 
job as an old one finishes, so if a long job comes along, the other threads 
will keep operating on the shorter ones.  `@qthreads` itself does use the 
primary thread, but its cousin `@qbthreads` uses the same strategy but in the background.
There are also `qmap`, `qforeach`, `qbmap`, and `qbforeach`.

The package also exposes a lower-level `@tspawnat` macro that mimics the 
`Base.Threads.@spawn` macro, but allows direct thread assignment for users who 
want to develop their own scheduling.

### Simple Macro/Function Selection

|                      | Foreground (primary allowed) |  Background (primary forbidden) |
| -------------------- | ---------------------------- | ------------------------------- |
| **Uniform tasks**    | <ul><li>`Base.Threads.@threads`</li><li>`ThreadPools.pmap(fn, itrs)`</li><li>`ThreadPools.pforeach(fn, itrs)`</li></ul> | <ul><li>`ThreadPools.@bthreads`</li><li>`ThreadPools.bmap(fn, itrs)`</li><li>`ThreadPools.bforeach(fn, itrs)`</li></ul> |
| **Nonuniform tasks** | <ul><li>`ThreadPools.@qthreads`</li><li>`ThreadPools.qmap(fn, itrs)`</li><li>`ThreadPools.qforeach(fn, itrs)`</li></ul> | <ul><li>`ThreadPools.@qbthreads`</li><li>`ThreadPools.qbmap(fn, itrs)`</li><li>`ThreadPools.qbforeach(fn, itrs)`</li></ul> |


## Job Logging for Performance Tuning

Each of the above macros comes with a logging version that allows the user to 
analyze the performance of the chosen strategy and thread count:

|                      | Foreground  |  Background  |
| -------------------- | ----------- | ------------ |
| **Uniform tasks**    | <ul><li>`ThreadPools.@logthreads`</li><li>`ThreadPools.logpmap(fn, itrs)`</li><li>`ThreadPools.logpforeach(fn, itrs)`</li></ul> | <ul><li>`ThreadPools.@logbthreads`</li><li>`ThreadPools.logbmap(fn, itrs)`</li><li>`ThreadPools.logbforeach(fn, itrs)`</li></ul> |
| **Nonuniform tasks** | <ul><li>`ThreadPools.@logqthreads`</li><li>`ThreadPools.logqmap(fn, itrs)`</li><li>`ThreadPools.logqforeach(fn, itrs)`</li></ul> | <ul><li>`ThreadPools.@logqbthreads`</li><li>`ThreadPools.logqbmap(fn, itrs)`</li><li>`ThreadPools.logqbforeach(fn, itrs)`</li></ul> |

Please see below for usage examples.

## Advanced API

The above macros invoke two base structures, `StaticPool` and `QueuePool`, each of which can 
be assigned to a subset of the available threads.  This allows for composition with the
`pwith` and `@pthreads` command, and usage in more complex scenarios, such as stack
processing.  See  https://tro3.github.io/ThreadPools.jl for more detail.


## Usage

Each of the simple API functions can be used like the `Base` versions of the 
same function: 

```julia
julia> @qbthreads for x in 1:3
         println("$x $(Threads.threadid())")
       end
2 3
3 4
1 2

julia> bmap([1,2,3]) do x
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

julia> t = @tspawnat 4 Threads.threadid()
Task (runnable) @0x0000000010743c70

julia> fetch(t)
4
```
Note that the first two examples above use the background versions and no 
threadid==1 is seen.  Also note that while the execution order is not 
guaranteed across threads, but the result of `bmap` will of course match 
the input. 

## Logger Usage

The logging versions of the above functions all produce an `AbstractThreadPool` 
object that has an in-memory log of the start and stop times of each job that 
ran through the pool.  A `PlotRecipe` from `RecipesBase` is exposed in the 
package, so all that is needed to generate a visualization of the job times is 
the `plot` command from `Plots`.  In these plots, each job is shown by index,
start time, and stop time and is given a color corresponding to its thread:

```julia
julia> using Plots

julia> pool = logpforeach(x -> sleep(0.1*x), 1:8);

julia> plot(pool)
```
![pforeach plot](https://tro3.github.io/ThreadPools.jl/build/img/staticlog.png)


```julia
julia> pool = logqforeach(x -> sleep(0.1*x), 1:8);

julia> plot(pool)
```
![qforeach plot](https://tro3.github.io/ThreadPools.jl/build/img/qlog.png)


Note the two different scheduling strategies are seen in the above plots. The 
`pforeach` log shows that the jobs were assigned in order: 1 & 2 to 
thread 1, 3 & 4 to thread 2, and so on.  The `qforeach` shows that each
job (any thread) is started when the previous job on that thread completes.
Because these jobs are very nonuniform (and stacked against the first
strategy), this results in the pre-assign method taking 25% longer.
