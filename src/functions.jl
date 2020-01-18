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
bgforeach(fn, itr)     = _poolforeach(fn, ThreadPool(), (itr,))
bgforeach(fn, itrs...) = _poolforeach(fn, ThreadPool(), itrs)
logbgforeach(fn, io, itr)     = _poolforeach(fn, LoggingThreadPool(io), (itr,))
logbgforeach(fn, io, itrs...) = _poolforeach(fn, LoggingThreadPool(io), itrs)


"""
    fgforeach(fn, itrs...) -> Nothing

Equivalent to [`bgforeach(fn, itrs...)`](@ref), but allows processing on the primary
thread.

# Example
```julia
julia> fgforeach([1,2,3,4,5]) do x
         println("\$(x+1) \$(Threads.threadid())")
       end
3 1
2 2
4 3
5 4
6 1
```
Note that the primary thread was used to process indexes 2 and 5, in this case.
"""
fgforeach(fn, itr)     = _poolforeach(fn, ThreadPool(true), (itr,))
fgforeach(fn, itrs...) = _poolforeach(fn, ThreadPool(true), itrs)

function _poolforeach(fn, pool, itrs)
    if Threads.nthreads() == 1
        return foreach(fn, itrs...)
    else
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
bgmap(fn, itr)::Vector{_detect_type(fn, itr)}      = _poolmap(fn, false, (itr,))
bgmap(fn, itrs...)::Vector{_detect_type(fn, itrs)} = _poolmap(fn, false, itrs)


"""
    fgmap(fn, itrs...) -> collection

Equivalent to [`bgmap(fn, itrs...)`](@ref), but allows processing on the primary
thread.

Note that the collection(s) supplied must be of equal and finite length.

# Example
```julia
julia> fgmap([1,2,3,4,5]) do x
         println("\$x \$(Threads.threadid())")
         x^2
       end
4 4
1 2
3 3
5 4
2 1
5-element Array{Int64,1}:
1
4
9
16
25
```
Note that the primary thread was used to process index 2, in this case.
"""
fgmap(fn, itr)::Vector{_detect_type(fn, itr)}      = _poolmap(fn, true, (itr,))
fgmap(fn, itrs...)::Vector{_detect_type(fn, itrs)} = _poolmap(fn, true, itrs)

_detect_type(fn, itr) = eltype(map(fn, empty(itr)))
_detect_type(fn, itrs::Tuple) = eltype(map(fn, [empty(x) for x in itrs]...))

function _poolmap(fn, allow_primary, itrs)
    if Threads.nthreads() == 1
        return map(fn, itrs...)
    else
        N = length(zip(itrs...))
        result = Vector{_detect_type(fn, itrs)}(undef, N)
        _fn = (ind, x) -> (ind, fn(x...))
        pool = ThreadPool(allow_primary)
        @async begin
            for (ind, item) in enumerate(zip(itrs...))
                put!(pool, _fn, ind, item)
            end
            close(pool)
        end
        for (ind, y) in results(pool)
            @inbounds result[ind] = y
        end
        return result
    end
end

"""
    @bgthreads

A macro to parallelize a for-loop to run with multiple threads, preventing use
of the primary.  
    
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


"""
    @fgthreads

A macro to parallelize a for-loop to run with multiple threads, allowing use
of the primary. 
    
Equivalent to [`@bgthreads`](@ref), but allows processing on the primary
thread.

# Example
```julia
julia> @fgthreads for x in 1:5
    println("\$x \$(Threads.threadid())")
   end
4 3
1 4
2 2
5 3
3 1
```
Note that the primary thread was used to process index 3, in this case.
"""
macro fgthreads(args...)
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
                fgforeach($(esc(range))) do $(esc(index))
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