
#############################
# Internal Structures
#############################

const MaybeTask = Union{Nothing, Task}

mutable struct LoggedQueuePool <: AbstractThreadPool
    inq  :: Channel{Task}
    outq :: Channel{Task}
    cnt  :: Threads.Atomic{Int}
    lck  :: ReentrantLock
    recs :: Vector{ThreadRecord}
    ind  :: Int
    t0   :: UInt64
    log  :: ThreadLog

    LoggedQueuePool(tids, handler::Function) = begin
        N = length(tids)
        pool = new(Channel{Task}(N), Channel{Task}(N), Threads.Atomic{Int}(0), ReentrantLock(), ThreadRecord[], 0, time_ns(), ThreadLog())
        Threads.@threads for tid in 1:Threads.nthreads()
            if tid in tids
                @async handler(pool)
            end
        end
        return pool
    end
end

function _default_log_handler(pool)
    t0 = time_ns()
    tid = Threads.threadid()
    for t in pool.inq
        lock(pool.lck)
        pool.ind += 1
        ind = pool.ind
        push!(pool.recs, (ind, tid, true, time_ns()))
        unlock(pool.lck)
        schedule(t)
        wait(t)
        lock(pool.lck)
        push!(pool.recs, (ind, tid, false, time_ns()))
        unlock(pool.lck)
        put!(pool.outq, t)
        Threads.atomic_sub!(pool.cnt, 1)
    end
end


#############################
# Constructors / Finalizer
#############################

"""
    LoggedQueuePool(io, thrd0=1, nthrds=Threads.nthreads())

The main LoggedQueuePool object. Its API mimics that of a `Channel{Task}`, but each
submitted task is executed on a different thread.  If `allow_primary` is true, 
the assigned thread might be the primary, which will interfere with future 
thread management for the duration of any heavy-computational (blocking)
processes.  If it is false, all assigned threads will be off of the primary.
Each thread will only be allowed one Task at a time, but each thread will 
backfill with the next queued Task immediately on completion of the previous,
without regard to how bust the other threads may be.  
"""
function LoggedQueuePool(thrd0::Integer=1, nthrds::Integer=Threads.nthreads())
    thrd0 = min(thrd0, Threads.nthreads())
    thrd1 = min(thrd0+nthrds-1, Threads.nthreads())
    return LoggedQueuePool(thrd0:thrd1, _default_log_handler)
end



#############################
# LoggedQueuePool API
#############################

"""
    Base.put!(pool::LoggedQueuePool, t::Task)

Put the task `t` into the pool, blocking until the pool has
an available thread.
"""
function Base.put!(pool::LoggedQueuePool, t::Task)
    Threads.atomic_add!(pool.cnt, 1)    
    put!(pool.inq, t)
end


"""
    Base.put!(pool::LoggedQueuePool, fn::Function, args...)
    Base.put!(fn::Function, pool::LoggedQueuePool, args...)

Creates a task that runs `fn(args...)` and adds it to the pool, blocking 
until the pool has an available thread.
"""
Base.put!(pool::LoggedQueuePool, fn::Function, args...) = Base.put!(pool, Task(()->fn(args...)))
Base.put!(fn::Function, pool::LoggedQueuePool, args...) = Base.put!(pool, Task(()->fn(args...)))


"""
    Base.take!(pool::LoggedQueuePool) -> Task

Takes the next available completed task from the pool, blocking until a
task is available.  
"""
Base.take!(pool::LoggedQueuePool) = fetch(take!(pool.outq))


"""
    Base.close(pool::LoggedQueuePool)

Shuts down the pool, closing the internal thread handlers.  It is safe
to issue this command after all Tasks have been submitted, regardless of
the Task completion status. If issued while the pool is still active, it 
will `yield` until all tasks have been completed. 
"""
function Base.close(pool::LoggedQueuePool)
    close(pool.inq)
    while pool.cnt[] > 0
        sleep(0.1)
        yield()
    end
    close(pool.outq)
    _recordstolog!(pool.log, pool.recs, pool. t0)
end


"""
    Base.iterate(pool::LoggedQueuePool[, state])

Iterates over the completed Tasks, grabbing the next one available
and ending when the pool has been `close`ed.
"""
Base.iterate(pool::LoggedQueuePool, state=nothing) = iterate(pool.outq, state)
Base.IteratorSize(::LoggedQueuePool) = Base.SizeUnknown()
Base.eltype(::LoggedQueuePool) = Task


"""
    ThreadPools.isactive(pool::LoggedQueuePool)

Returns `true` if there are queued Tasks anywhere in the pool, either
awaiting execution, executing, or waiting to be retrieved.
"""
isactive(pool::LoggedQueuePool) = isready(pool.inq) || isready(pool.outq) || pool.cnt[] > 0



#############################
# Result Iterator
#############################

results(pool::LoggedQueuePool) = ResultIterator(pool)



#############################
# ThreadPool Interface
#############################

function pmap(pool::LoggedQueuePool, fn::Function, itr)
    N = length(itr)
    sizehint!(pool.recs, N)
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
