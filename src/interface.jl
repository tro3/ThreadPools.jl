import Core.Compiler

abstract type AbstractThreadPool end

_detect_type(fn, itr) = Core.Compiler.return_type(fn, Tuple{eltype(itr)})


"""
    tforeach(fn, pool, itr)

Mimics `Base.foreach`, but launches the function evaluations onto the provided 
pool to assign the tasks.

# Example
```
julia> pool = twith(ThreadPools.LoggedQueuePool(1,2)) do pool
         tforeach(x -> println((x,Threads.threadid())), pool, 1:8)
       end;
(2, 2)
(1, 1)
(3, 2)
(5, 2)
(4, 1)
(6, 2)
(7, 1)
(8, 2)

julia> plot(pool)
```
"""
function tforeach(fn, pool::AbstractThreadPool, itr)
    tmap(fn, pool, itr)
    nothing
end

tforeach(fn, pool::AbstractThreadPool, itr1, itrs...) = tforeach(x -> fn(x...), pool, zip(itr1, itrs...))


"""
    tmap(fn, pool, itr)

Mimics `Base.map`, but launches the function evaluations onto the provided 
pool to assign the tasks.

# Example
```
julia> pool = twith(ThreadPools.LoggedQueuePool(1,2)) do pool
         tmap(pool, 1:8) do x
           println((x,Threads.threadid()))
         end
       end;
(2, 2)
(1, 1)
(3, 2)
(4, 1)
(5, 2)
(6, 1)
(7, 2)
(8, 1)

julia> plot(pool)
```
"""
tmap(fn, pool::AbstractThreadPool, itr1, itrs...) = tmap(x -> fn(x...), pool, zip(itr1, itrs...))


"""
    twith(fn, pool) -> pool

Apply the functon `fn` to the provided pool and close the pool.  Returns the 
closed pool for any desired analysis or plotting. 

# Example
```
julia> twith(ThreadPools.QueuePool(1,2)) do pool
         tforeach(x -> println((x,Threads.threadid())), pool, 1:8)
       end;
(2, 2)
(1, 1)
(3, 2)
(4, 1)
(5, 2)
(6, 1)
(7, 2)
(8, 1)
```
Note in the above example, only two threads were used, as set by the 
`QueuePool` setting.
"""
function twith(fn, pool)
    fn(pool)
    close(pool)
    pool
end


"""
    @tthreads pool

Mimic the `Base.Threads.@threads` macro, but uses the provided pool to 
assign the tasks.

# Example
```
julia> twith(ThreadPools.QueuePool(1,2)) do pool
         @tthreads pool for x in 1:8
           println((x,Threads.threadid()))
         end
       end;
(2, 2)
(3, 2)
(1, 1)
(4, 2)
(5, 1)
(6, 2)
(8, 2)
(7, 1)
```
"""
macro tthreads(pool, args...)
    na = length(args)
    if na != 1
        throw(ArgumentError("wrong number of arguments in @tthreads"))
    end
    ex = args[1]
    if !isa(ex, Expr)
        throw(ArgumentError("need an expression argument to @tthreads"))
    end
    if ex.head === :for
        if ex.args[1] isa Expr && ex.args[1].head === :(=)
            index = ex.args[1].args[1]
            range = ex.args[1].args[2]
            body = ex.args[2]
            return quote
                tforeach($(esc(pool)), $(esc(range))) do $(esc(index))
                    $(esc(body))
                end
            end
        else
            throw(ArgumentError("nested outer loops are not currently supported by @tthreads"))
        end
    else
        throw(ArgumentError("unrecognized argument to @tthreads"))
    end
end

function Base.finalize(pool::AbstractThreadPool)
    close(pool)
end


"""
    Base.close(pool::AbstractThreadPool)

Closes the pool, shuts down any handlers and finalizes any logging activities. 
"""
function Base.close(pool::AbstractThreadPool)
    nothing
end
