
function _pthread_macro(pool, log, args...)
    na = length(args)
    if na != 1
        throw(ArgumentError("wrong number of arguments in thread macro"))
    end
    ex = args[1]
    if !isa(ex, Expr)
        throw(ArgumentError("need an expression argument to thread macro"))
    end
    if ex.head === :for
        if ex.args[1] isa Expr && ex.args[1].head === :(=)
            index = ex.args[1].args[1]
            range = ex.args[1].args[2]
            body = ex.args[2]
            return quote
                pool = pwith($pool) do p
                    tforeach(p, $(esc(range))) do $(esc(index))
                        $(esc(body))
                    end
                end
                $(esc(log)) ? pool : nothing
            end
        else
            throw(ArgumentError("nested outer loops are not currently supported by thread macro"))
        end
    else
        throw(ArgumentError("unrecognized argument tothread macro"))
    end
end

"""
    @bthreads

Mimics `Base.Threads.@threads, but keeps the iterated tasks off if the primary 
thread.`

# Example
```julia
julia> @bthreads for x in 1:8
         println((x, Threads.threadid()))
       end
(1, 2)
(6, 4)
(3, 3)
(7, 4)
(4, 3)
(8, 4)
(5, 3)
(2, 2)
```
Note that execution order is not guaranteed, but the primary thread does not
show up on any of the jobs.
"""
macro bthreads(args...) 
    return _pthread_macro(:(StaticPool(2)), false, args...)
    nothing
end

"""
    @qthreads

Mimics `Base.Threads.@threads`, but uses a task queueing strategy, only starting 
a new task when an previous one (on any thread) has completed.  This can provide
performance advantages when the iterated tasks are very nonuniform in length. 
The primary thread is used.  To prevent usage of the primary thread, see 
[`@qbthreads`](@ref).

# Example
```julia
julia> @qthreads for x in 1:8
         println((x, Threads.threadid()))
       end
(2, 4)
(3, 3)
(4, 2)
(5, 4)
(6, 3)
(7, 2)
(8, 4)
(1, 1)
```
Note that execution order is not guaranteed and the primary thread is used.
"""
macro qthreads(args...) 
    return _pthread_macro(:(QueuePool(1)), false, args...)
end

"""
    @qbthreads

Mimics `Base.Threads.@threads`, but uses a task queueing strategy, only starting 
a new task when an previous one (on any thread) has completed.  This can provide
performance advantages when the iterated tasks are very nonuniform in length. 
The primary thread is not used.  To allow usage of the primary thread, see 
[`@qthreads`](@ref).

# Example
```julia
julia> @qbthreads for x in 1:8
         println((x, Threads.threadid()))
       end
(2, 4)
(3, 2)
(1, 3)
(4, 4)
(5, 2)
(6, 3)
(7, 4)
(8, 2)
```
Note that execution order is not guaranteed, but the primary thread does not
show up on any of the jobs.
"""
macro qbthreads(args...) 
    return _pthread_macro(:(QueuePool(2)), false, args...)
end

"""
    @logthreads -> pool

Mimics `Base.Threads.@threads`.  Returns a logged pool that can be analyzed with 
the logging functions and `plot`ted.

# Example
```julia
julia> pool = @logthreads for x in 1:8
         println((x, Threads.threadid()))
       end;
(1, 1)
(5, 3)
(7, 4)
(2, 1)
(6, 3)
(8, 4)
(3, 2)
(4, 2)

julia> plot(pool)
```
Note that execution order is not guaranteed and the primary thread is used.
"""
macro logthreads(args...) 
    return _pthread_macro(:(LoggedStaticPool(1)), true, args...)
end

"""
    @logbthreads -> pool

Mimics `Base.Threads.@threads, but keeps the iterated tasks off if the primary 
thread.`  Returns a logged pool that can be analyzed with the logging functions 
and `plot`ted.

# Example
```julia
julia> pool = @logbthreads for x in 1:8
         println((x, Threads.threadid()))
       end;
(3, 4)
(2, 3)
(1, 2)
(4, 4)
(5, 3)
(6, 2)
(8, 3)
(7, 4)

julia> plot(pool)
```
Note that execution order is not guaranteed, but the primary thread does not
show up on any of the jobs.
"""
macro logbthreads(args...) 
    return _pthread_macro(:(LoggedStaticPool(2)), true, args...)
end

"""
    @logqthreads -> pool

Mimics `Base.Threads.@threads`, but uses a task queueing strategy, only starting 
a new task when an previous one (on any thread) has completed.  Returns a logged 
pool that can be analyzed with the logging functions and `plot`ted. The primary 
thread is used.  To prevent usage of the primary thread, see 
[`@logqbthreads`](@ref).

# Example
```julia
julia> pool = @logqthreads for x in 1:8
         println((x, Threads.threadid()))
       end;
(1, 1)
(3, 2)
(7, 4)
(5, 3)
(2, 1)
(8, 4)
(6, 3)
(4, 2)

julia> plot(pool)
```
Note that execution order is not guaranteed and the primary thread is used.
"""
macro logqthreads(args...) 
    return _pthread_macro(:(LoggedQueuePool(1)), true, args...)
end

"""
    @logqbthreads -> pool

Mimics `Base.Threads.@threads`, but uses a task queueing strategy, only starting 
a new task when an previous one (on any thread) has completed.  Returns a logged 
pool that can be analyzed with the logging functions and `plot`ted. The primary 
thread is not used.  To allow usage of the primary thread, see 
[`@logqthreads`](@ref).

# Example
```julia
julia> pool = @logqbthreads for x in 1:8
         println((x, Threads.threadid()))
       end;
(2, 3)
(1, 4)
(3, 2)
(4, 3)
(5, 4)
(6, 2)
(7, 3)
(8, 4)

julia> plot(pool)
```
Note that execution order is not guaranteed, but the primary thread does not
show up on any of the jobs.
"""
macro logqbthreads(args...) 
    return _pthread_macro(:(LoggedQueuePool(2)), true, args...)
end


"""
    @tspawnat tid -> task

Mimics `Base.Threads.@spawn`, but assigns the task to thread `tid`.

# Example
```julia
julia> t = @tspawnat 4 Threads.threadid()
Task (runnable) @0x0000000010743c70

julia> fetch(t)
4
```
"""
macro tspawnat(thrdid, expr)
    if VERSION >= v"1.4"
        letargs = Base._lift_one_interp!(expr)
    
        thunk = esc(:(()->($expr)))
        var = esc(Base.sync_varname)
        tid = esc(thrdid)
        quote
            if $tid < 1 || $tid > Threads.nthreads()
                throw(AssertionError("@tspawnat thread assignment ($($tid)) must be between 1 and Threads.nthreads() (1:$(Threads.nthreads()))"))
            end
            let $(letargs...)
                local task = Task($thunk)
                task.sticky = false
                ccall(:jl_set_task_tid, Cvoid, (Any, Cint), task, $tid-1)
                if $(Expr(:islocal, var))
                    put!($var, task)
                end
                schedule(task)
                task
            end
        end
    else
        thunk = esc(:(()->($expr)))
        var = esc(Base.sync_varname)
        tid = esc(thrdid)
        quote
            if $tid < 1 || $tid > Threads.nthreads()
                throw(AssertionError("@tspawnat thread assignment ($($tid)) must be between 1 and Threads.nthreads() (1:$(Threads.nthreads()))"))
            end
            local task = Task($thunk)
            task.sticky = false
            ccall(:jl_set_task_tid, Cvoid, (Any, Cint), task, $tid-1)
            if $(Expr(:isdefined, var))
                push!($var, task)
            end
            schedule(task)
            task
        end
    end
end
