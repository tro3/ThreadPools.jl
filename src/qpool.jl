
#############################
# Internal Structures
#############################

const MaybeTask = Union{Nothing, Task}

mutable struct QueuePool <: AbstractThreadPool
    inq  :: Channel{Task}
    outq :: Channel{Task}
    cnt  :: Threads.Atomic{Int}

    QueuePool(tids, handler::Function) = begin
        N = length(tids)
        pool = new(Channel{Task}(N), Channel{Task}(N), Threads.Atomic{Int}(0))
        Threads.@threads for tid in 1:Threads.nthreads()
            if tid in tids
                @async handler(pool)
            end
        end
        return pool
    end
end

function _default_handler(pool)
    for t in pool.inq
        schedule(t)
        wait(t)
        put!(pool.outq, t)
        Threads.atomic_sub!(pool.cnt, 1)
    end
end



#############################
# Constructors
#############################

"""
    QueuePool(init_thrd=1, nthrds=Threads.nthreads())

The main QueuePool object. Its API mimics that of a `Channel{Task}`, but each
submitted task is executed on a different thread.  If `allow_primary` is true, 
the assigned thread might be the primary, which will interfere with future 
thread management for the duration of any heavy-computational (blocking)
processes.  If it is false, all assigned threads will be off of the primary.
Each thread will only be allowed one Task at a time, but each thread will 
backfill with the next queued Task immediately on completion of the previous,
without regard to how bust the other threads may be.  
"""
function QueuePool(init_thrd::Integer=1, nthrds::Integer=Threads.nthreads())
    thrd0 = min(init_thrd, Threads.nthreads())
    thrd1 = min(thrd0+nthrds-1, Threads.nthreads())
    return QueuePool(thrd0:thrd1, _default_handler)
end



#############################
# QueuePool API
#############################

"""
    Base.put!(pool::QueuePool, t::Task)

Put the task `t` into the pool, blocking until the pool has
an available thread.
"""
function Base.put!(pool::QueuePool, t::Task)
    Threads.atomic_add!(pool.cnt, 1)    
    put!(pool.inq, t)
end


"""
    Base.put!(pool::QueuePool, fn::Function, args...)
    Base.put!(fn::Function, pool::QueuePool, args...)

Creates a task that runs `fn(args...)` and adds it to the pool, blocking 
until the pool has an available thread.
"""
Base.put!(pool::QueuePool, fn::Function, args...) = Base.put!(pool, Task(()->fn(args...)))
Base.put!(fn::Function, pool::QueuePool, args...) = Base.put!(pool, Task(()->fn(args...)))


"""
    Base.take!(pool::QueuePool) -> Task

Takes the next available completed task from the pool, blocking until a
task is available.  
"""
Base.take!(pool::QueuePool) = fetch(take!(pool.outq))


"""
    Base.close(pool::QueuePool)

Shuts down the pool, closing the internal thread handlers.  It is safe
to issue this command after all Tasks have been submitted, regardless of
the Task completion status. If issued while the pool is still active, it 
will `yield` until all tasks have been completed. 
"""
function Base.close(pool::QueuePool)
    close(pool.inq)
    while pool.cnt[] > 0
        sleep(0.1)
        yield()
    end
    close(pool.outq)
end


"""
    Base.iterate(pool::QueuePool[, state])

Iterates over the completed Tasks, grabbing the next one available
and ending when the pool has been `close`ed.
"""
Base.iterate(pool::QueuePool, state=nothing) = iterate(pool.outq, state)
Base.IteratorSize(::QueuePool) = Base.SizeUnknown()
Base.eltype(::QueuePool) = Task


"""
    ThreadPools.isactive(pool::QueuePool)

Returns `true` if there are queued Tasks anywhere in the pool, either
awaiting execution, executing, or waiting to be retrieved.
"""
isactive(pool::QueuePool) = isready(pool.inq) || isready(pool.outq) || pool.cnt[] > 0



#############################
# Result Iterator
#############################

struct ResultIterator
    pool :: AbstractThreadPool
end

"""
    results(pool::QueuePool) -> result iterator

Returns an iterator over the `fetch`ed results of the pooled tasks.

# Example

```julia
julia> pool = QueuePool();

julia> @async begin
         for i in 1:4
           put!(pool, x -> 2*x, i)
         end
         close(pool)
       end;

julia> for r in results(pool)
         println(r)
       end
6
2
4
8
```
Note that the execution order across the threads is not guaranteed.
"""
results(pool::QueuePool) = ResultIterator(pool)

function Base.iterate(itr::ResultIterator, state=nothing)
    x = iterate(itr.pool.outq, state)
    isnothing(x) && return nothing
    return fetch(x[1]), nothing
end

Base.IteratorSize(::ResultIterator) = Base.SizeUnknown()
Base.IteratorEltype(::ResultIterator) = Base.EltypeUnknown() 



#############################
# ThreadPool Interface
#############################

function pmap(pool::QueuePool, fn::Function, itr)
    N = length(itr)
    result = Vector{_detect_type(fn, itr)}(undef, N)
    _fn = (ind, x) -> (ind, fn(x))
    @async begin
        for (ind, item) in enumerate(itr)
            put!(pool, _fn, ind, item)
        end
    end
    for i in 1:N
        (ind, y) = fetch(take!(pool))
        @inbounds result[ind] = y
    end
    return result
end
