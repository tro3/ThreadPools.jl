
abstract type AbstractThreadPool end

_detect_type(fn, itr) = eltype(map(fn, empty(itr)))
_detect_type(fn, itrs::Tuple) = eltype(map(fn, [empty(x) for x in itrs]...))


"""
    pforeach(pool, fn::Function, itr)
    pforeach(fn::Function, pool, itr)

Mimics `Base.foreach`, but launches the function evaluations onto the provided 
pool to assign the tasks.

# Example
```
julia> pool = pwith(ThreadPools.LoggedQueuePool(1,2)) do pool
         pforeach(pool,  x -> println((x,Threads.threadid())), 1:8)
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
function pforeach(pool, fn::Function, itr::AbstractVector)
    pmap(pool, fn, itr)
    nothing
end

pforeach(fn::Function, pool, itr) = pforeach(pool, fn, itr::AbstractVector)
pforeach(pool, fn::Function, itrs...) = pforeach(pool, (x) -> fn(x...), zip(itrs...))
pforeach(fn::Function, pool, itrs...) = pforeach(pool, (x) -> fn(x...), zip(itrs...))


# function pmap(pool::AbstractThreadPool, fn::Function, itr::AbstractVector)
#     error("Not Implemented")
# end

"""
    pmap(pool, fn::Function, itr)
    pmap(fn::Function, pool, itr)

Mimics `Base.map`, but launches the function evaluations onto the provided 
pool to assign the tasks.

# Example
```
julia> pool = pwith(ThreadPools.LoggedQueuePool(1,2)) do pool
         pmap(pool, 1:8) do x
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
pmap(fn::Function, pool, itr) = pmap(pool, fn, itr)
pmap(pool, fn::Function, itrs...) = pmap(pool, (x) -> fn(x...), zip(itrs...))
pmap(fn::Function, pool, itrs...) = pmap(pool, (x) -> fn(x...), zip(itrs...))


"""
    pwith(fn::Function, pool) -> pool

Apply the functon `fn` to the provided pool and close the pool.  Returns the 
closed pool for any desired analysis or plotting. 

# Example
```
julia> pwith(ThreadPools.QueuePool(1,2)) do pool
         pforeach(pool, x -> println((x,Threads.threadid())), 1:8)
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
function pwith(fn::Function, pool)
    fn(pool)
    close(pool)
    pool
end


"""
    @pthreads pool

Mimic the `Base.Threads.@threads` macro, but uses the provided pool to 
assign the tasks.

# Example
```
julia> pwith(ThreadPools.QueuePool(1,2)) do pool
         @pthreads pool for x in 1:8
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
macro pthreads(pool, args...)
    na = length(args)
    if na != 1
        throw(ArgumentError("wrong number of arguments in @pthreads"))
    end
    ex = args[1]
    if !isa(ex, Expr)
        throw(ArgumentError("need an expression argument to @pthreads"))
    end
    if ex.head === :for
        if ex.args[1] isa Expr && ex.args[1].head === :(=)
            index = ex.args[1].args[1]
            range = ex.args[1].args[2]
            body = ex.args[2]
            return quote
                pforeach($(esc(pool)), $(esc(range))) do $(esc(index))
                    $(esc(body))
                end
            end
        else
            throw(ArgumentError("nested outer loops are not currently supported by @pthreads"))
        end
    else
        throw(ArgumentError("unrecognized argument to @pthreads"))
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
