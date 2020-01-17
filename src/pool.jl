
const MaybeTask = Union{Nothing, Task}

"""
    ThreadPool(allow_primary=false)

The main ThreadPool object. Its API mimics that of a `Channel{Task}`, but each
submitted task is executed on a different thread.  If `allow_primary` is true, 
the assigned thread might be the primary, which will interfere with future 
thread management for the duration of any heavy-computational (blocking)
processes.  If it is false, all assigned threads will be off of the primary.
Each thread will only be allowed one Task at a time, but each thread will 
backfill with the next queued Task immediately on completion of the previous,
without regard to how bust the other threads may be.  
"""
mutable struct ThreadPool
    inq  :: Channel{Task}
    outq :: Channel{Task}
    cnt  :: Threads.Atomic{Int}

    ThreadPool(allow_primary=false) = begin
        allow_primary = allow_primary || Threads.nthreads() == 1
        N = Threads.nthreads() - (allow_primary ? 0 : 1)
        pool = new(Channel{Task}(N), Channel{Task}(N), Threads.Atomic{Int}(0))
        Threads.@threads for i in 1:Threads.nthreads()
            if allow_primary || Threads.threadid() > 1
                @async for t in pool.inq
                    schedule(t)
                    wait(t)
                    put!(pool.outq, t)
                    Threads.atomic_sub!(pool.cnt, 1)
                end
            end
        end
        return pool
    end

end


"""
    Base.put!(pool::ThreadPool, t::Task)

Put the task `t` into the pool, blocking until the pool has
an available thread.
"""
function Base.put!(pool::ThreadPool, t::Task)
    Threads.atomic_add!(pool.cnt, 1)    
    put!(pool.inq, t)
end


"""
    Base.put!(pool::ThreadPool, fn::Function, args...)
    Base.put!(fn::Function, pool::ThreadPool, args...)

Creates a task that runs `fn(args...)` and adds it to the pool, blocking 
until the pool has an available thread.
"""
Base.put!(pool::ThreadPool, fn::Function, args...) = Base.put!(pool, Task(()->fn(args...)))
Base.put!(fn::Function, pool::ThreadPool, args...) = Base.put!(pool, Task(()->fn(args...)))


"""
    Base.take!(pool::ThreadPool) -> Task

Takes the next available completed task from the pool, blocking until a
task is available.  
"""
Base.take!(pool::ThreadPool) = fetch(take!(pool.outq))


"""
    Base.close(pool::ThreadPool)

Shuts down the pool, closing the internal thread handlers.  It is safe
to issue this command after all Tasks have been submitted, regardless of
the Task completion status. If issued while the pool is still active, it 
will `yield` until all tasks have been completed. 
"""
function Base.close(pool::ThreadPool)
    close(pool.inq)
    while pool.cnt[] > 0
        sleep(0.1)
        yield()
    end
    close(pool.outq)
end


"""
    Base.iterate(pool::ThreadPool[, state])

Iterates over the completed Tasks, grabbing the next one available
and ending when the pool has been `close`ed.
"""
Base.iterate(pool::ThreadPool, state=nothing) = iterate(pool.outq, state)
Base.IteratorSize(::ThreadPool) = Base.SizeUnknown()
Base.eltype(::ThreadPool) = Task


"""
    ThreadPools.isactive(pool::ThreadPool)

Returns `true` if there are queued Tasks anywhere in the pool, either
awaiting execution, executing, or waiting to be retrieved.
"""
isactive(pool::ThreadPool) = isready(pool.inq) || isready(pool.outq) || pool.cnt[] > 0