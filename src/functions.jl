"""
    bgforeach(fn, itrs...) -> Nothing

Mimics the 
[`Base.foreach`](https://docs.julialang.org/en/v1/base/collections/#Base.foreach) 
function, but spawns each iteration to a background thread.  Falls back to 
[`Base.foreach`](https://docs.julialang.org/en/v1/base/collections/#Base.foreach) 
when nthreads() == 1.

# Example
```julia
julia> bgforeach([1,2,3]) do x
    println("\$(x+1) \$(Threads.threadid())")
  end
3 3
4 4
2 2
```
Note that the execution order across the threads is not guaranteed.
"""
function bgforeach(fn, itr)
    if Threads.nthreads() == 1
        return foreach(fn, itr)
    else
        pool = ThreadPool()
        @async begin
            for item in itr
                put!(pool, fn, item)
            end
            close(pool)
        end
        collect(pool)
        nothing
    end
end

function bgforeach(fn, itrs...)
    if Threads.nthreads() == 1
        return foreach(fn, itrs...)
    else
        pool = ThreadPool()
        @async begin
            for item in zip(itrs...)
                put!(pool, fn, item...)
            end
            close(pool)
        end
        collect(pool)
        nothing
    end
end


"""
    bgmap(fn, itrs...) -> collection

Mimics the 
[`Base.map`](https://docs.julialang.org/en/v1/base/collections/#Base.map) 
function, but spawns each case to a background thread.  Falls back to 
`Base.map` when nthreads() == 1.

Note that the collection(s) supplied must be of equal and finite length.

# Example
```julia
julia> bgmap([1,2,3]) do x
         println("\$x \$(Threads.threadid())")
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
Note that while the thread execution order is not guaranteed, the final 
result will maintain the proper sequence.
"""
function bgmap(fn, itr)
    if Threads.nthreads() == 1
        return map(fn, itr)
    else
        result = Vector{eltype(map(fn, eltype(itr)[]))}(undef, length(itr))
        _fn = (ind, x) -> (ind, fn(x))
        pool = ThreadPool()
        @async begin
            for (ind, item) in enumerate(itr)
                put!(pool, _fn, ind, item)
            end
            close(pool)
        end
        for t in pool
            (ind, y) = fetch(t)
            @inbounds result[ind] = y
        end
        return result
    end
end

function bgmap(fn, itrs...)
    if Threads.nthreads() == 1
        return map(fn, itrs...)
    else
        N = length(zip(itrs...))
        result = Vector{eltype(map(fn, [eltype(x)[] for x in itrs]...))}(undef, N)
        _fn = (ind, x) -> (ind, fn(x...))
        pool = ThreadPool()
        @async begin
            for (ind, item) in enumerate(zip(itrs...))
                put!(pool, _fn, ind, item)
            end
            close(pool)
        end
        for t in pool
            (ind, y) = fetch(t)
            @inbounds result[ind] = y
        end
        return result
    end
end


"""
    @bgthreads

A macro to parallelize a for-loop to run with multiple threads. 
    
`@bgthreads` mimics the 
[`Threads.@threads`](https://docs.julialang.org/en/v1/base/multi-threading/#Base.Threads.@threads) 
macro, but keeps the activity off of the primary thread.  Will fall back 
gracefully to `Base.foreach` behavior when nthreads == 1.

# Example
```julia
julia> @bgthreads for x in 1:3
        println("\$x \$(Threads.threadid())")
       end
2 3
3 4
1 2
```
Note that the execution order across the threads is not guaranteed.
"""
macro bgthreads(args...)
    na = length(args)
    if na != 1
        throw(ArgumentError("wrong number of arguments in @bgthreads"))
    end
    ex = args[1]
    if !isa(ex, Expr)
        throw(ArgumentError("need an expression argument to @bgthreads"))
    end
    if ex.head === :for
        if ex.args[1] isa Expr && ex.args[1].head === :(=)
            index = ex.args[1].args[1]
            range = ex.args[1].args[2]
            body = ex.args[2]
            return quote
                bgforeach($(esc(range))) do $(esc(index))
                    $(esc(body))
                end
            end
        else
            throw(ArgumentError("nested outer loops are not currently supported by @bgthreads"))
        end
    else
        throw(ArgumentError("unrecognized argument to @bgthreads"))
    end
end
