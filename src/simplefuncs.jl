
"""
    tmap(fn, itrs...) -> collection

Mimics `Base.map`, but launches the function evaluations onto all available 
threads, using a pre-assigned scheduling strategy appropriate for uniform
task durations.

# Example
```julia
julia> tmap(x -> begin; println((x,Threads.threadid())); x^2; end, 1:8)'
(7, 4)
(5, 3)
(8, 4)
(1, 1)
(6, 3)
(2, 1)
(3, 2)
(4, 2)
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
 1  4  9  16  25  36  49  64
```
Note that while the execution order is not guaranteed, the result order is. 
Also note that the primary thread is used.
"""
function tmap(fn, itrs...)
    pool = StaticPool()
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return result
end

"""
    bmap(fn, itrs...) -> collection

Mimics `Base.map`, but launches the function evaluations onto all available 
threads except the primary, using a pre-assigned scheduling strategy 
appropriate for uniform task durations.

# Example
```julia
julia> bmap(x -> begin; println((x,Threads.threadid())); x^2; end, 1:8)'
(6, 4)
(1, 2)
(3, 3)
(2, 2)
(4, 3)
(7, 4)
(5, 3)
(8, 4)
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
 1  4  9  16  25  36  49  64
```
Note that while the execution order is not guaranteed, the result order is, 
Also note that the primary thread is not used.
"""
function bmap(fn, itrs...)
    pool = StaticPool(2)
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return result
end

"""
    qmap(fn, itrs...) -> collection

Mimics `Base.map`, but launches the function evaluations onto all available 
threads, using a queued scheduling strategy appropriate for nonuniform
task durations.

# Example
```julia
julia> qmap(x -> begin; println((x,Threads.threadid())); x^2; end, 1:8)'
(2, 3)
(3, 2)
(4, 4)
(5, 3)
(6, 2)
(7, 4)
(8, 3)
(1, 1)
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
 1  4  9  16  25  36  49  64
```
Note that while the execution order is not guaranteed, the result order is. 
Also note that the primary thread is used.
"""
function qmap(fn, itrs...)
    pool = QueuePool()
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return result
end

"""
    qbmap(fn, itrs...) -> collection

Mimics `Base.map`, but launches the function evaluations onto all available 
threads except the primary, using a queued scheduling strategy appropriate 
for nonuniform task durations.

# Example
```julia
julia> qbmap(x -> begin; println((x,Threads.threadid())); x^2; end, 1:8)'
(2, 3)
(1, 2)
(3, 4)
(5, 2)
(4, 3)
(6, 4)
(7, 2)
(8, 3)
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
 1  4  9  16  25  36  49  64
```
Note that while the execution order is not guaranteed, the result order is, 
Also note that the primary thread is not used.
"""
function qbmap(fn, itrs...)
    pool = QueuePool(2)
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return result
end

"""
    logtmap(fn, itrs...) -> (pool, collection)

Mimics `Base.map`, but launches the function evaluations onto all available 
threads, using a pre-assigned scheduling strategy appropriate for uniform
task durations.  Also returns a logged pool that can be analyzed with 
the logging functions and `plot`ted.

# Example
```julia
julia> (pool, result) = logtmap(1:8) do x
         println((x,Threads.threadid()))
         x^2
       end;
(1, 1)
(3, 2)
(7, 4)
(5, 3)
(8, 4)
(4, 2)
(2, 1)
(6, 3)

julia> result'
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
1  4  9  16  25  36  49  64

julia> plot(pool)
```
Note that while the execution order is not guaranteed, the result order is. 
Also note that the primary thread is used.
"""
function logtmap(fn, itrs...)
    pool = LoggedStaticPool()
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool, result
end

"""
    logbmap(fn, itrs...) -> (pool, collection)

Mimics `Base.map`, but launches the function evaluations onto all available 
threads except the primary, using a pre-assigned scheduling strategy 
appropriate for uniform task durations.  Also returns a logged pool that can 
be analyzed with the logging functions and `plot`ted.

# Example
```julia
julia> (pool, result) = logbmap(1:8) do x
         println((x,Threads.threadid()))
         x^2
       end;
(1, 2)
(6, 4)
(3, 3)
(7, 4)
(2, 2)
(4, 3)
(8, 4)
(5, 3)

julia> result'
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
1  4  9  16  25  36  49  64

julia> plot(pool)
```
Note that while the execution order is not guaranteed, the result order is, 
Also note that the primary thread is not used.
"""
function logbmap(fn, itrs...)
    pool = LoggedStaticPool(2)
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool, result
end

"""
    logqmap(fn, itrs...) -> (pool, collection)

Mimics `Base.map`, but launches the function evaluations onto all available 
threads, using a queued scheduling strategy appropriate for nonuniform
task durations.  Also returns a logged pool that can be analyzed with the 
logging functions and `plot`ted.

# Example
```julia
julia> (pool, result) = logqmap(1:8) do x
         println((x,Threads.threadid()))
         x^2
        end;
(3, 3)
(4, 4)
(2, 2)
(5, 3)
(7, 2)
(6, 4)
(8, 3)
(1, 1)

julia> result'
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
1  4  9  16  25  36  49  64

julia> plot(pool)
```
Note that while the execution order is not guaranteed, the result order is. 
Also note that the primary thread is used.
"""
function logqmap(fn, itrs...)
    pool = LoggedQueuePool()
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool, result
end

"""
    logqbmap(fn, itrs...) -> (pool, collection)

Mimics `Base.map`, but launches the function evaluations onto all available 
threads except the primary, using a queued scheduling strategy appropriate 
for nonuniform task durations.  Also returns a logged pool that can be 
analyzed with the logging functions and `plot`ted.

# Example
```julia
julia> (pool, result) = logqbmap(1:8) do x
         println((x,Threads.threadid()))
         x^2
       end;
(3, 3)
(2, 4)
(1, 2)
(4, 3)
(5, 4)
(6, 2)
(7, 3)
(8, 4)

julia> result'
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
1  4  9  16  25  36  49  64

julia> plot(pool)
```
Note that while the execution order is not guaranteed, the result order is, 
Also note that the primary thread is not used.
"""
function logqbmap(fn, itrs...)
    pool = LoggedQueuePool(2)
    result = tmap(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool, result
end


"""
    tforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads, using a pre-assigned scheduling strategy appropriate for uniform
task durations.

# Example
```julia
julia> tforeach(x -> println((x,Threads.threadid())), 1:8)
(1, 1)
(3, 2)
(5, 3)
(2, 1)
(7, 4)
(4, 2)
(8, 4)
(6, 3)
```
Note that the execution order is not guaranteed, and that the primary thread 
is used.
"""
function tforeach(fn, itrs...)
    pool = StaticPool()
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    nothing
end


"""
    bforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads except the primary, using a pre-assigned scheduling strategy appropriate 
for uniform task durations.

# Example
```julia
julia> bforeach(x -> println((x,Threads.threadid())), 1:8)
(1, 2)
(6, 4)
(2, 2)
(7, 4)
(8, 4)
(3, 3)
(4, 3)
(5, 3)
```
Note that the execution order is not guaranteed, and that the primary thread 
is not used.
"""
function bforeach(fn, itrs...)
    pool = StaticPool(2)
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    nothing
end

"""
    qforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads, using a queued scheduling strategy appropriate for nonuniform
task durations.

# Example
```julia
julia> qforeach(x -> println((x,Threads.threadid())), 1:8)
(4, 3)
(2, 2)
(3, 4)
(5, 3)
(6, 2)
(7, 4)
(8, 3)
(1, 1)
```
Note that the execution order is not guaranteed, and that the primary thread 
is used.
"""
function qforeach(fn, itrs...)
    pool = QueuePool()
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    nothing
end


"""
    qbforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads except the primary, using a queued scheduling strategy appropriate for 
nonuniform task durations.

# Example
```julia
julia> qbforeach(x -> println((x,Threads.threadid())), 1:8)
(3, 3)
(2, 4)
(1, 2)
(4, 3)
(5, 4)
(6, 2)
(7, 3)
(8, 4)
```
Note that the execution order is not guaranteed, and that the primary thread 
is not used.
"""
function qbforeach(fn, itrs...)
    pool = QueuePool(2)
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    nothing
end



"""
    logtforeach(fn, itrs...) -> pool

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads, using a pre-assigned scheduling strategy appropriate for uniform
task durations.  Returns a logged pool that can be analyzed with 
the logging functions and `plot`ted.

# Example
```julia
julia> pool = logtforeach(x -> println((x,Threads.threadid())), 1:8);
(1, 1)
(3, 2)
(7, 4)
(2, 1)
(4, 2)
(5, 3)
(8, 4)
(6, 3)

julia> plot(pool)
```
Note that the execution order is not guaranteed, and that the primary thread 
is used.
"""
function logtforeach(fn, itrs...)
    pool = LoggedStaticPool()
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool
end


"""
    logbforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads except the primary, using a pre-assigned scheduling strategy appropriate 
for uniform task durations.  Returns a logged pool that can be analyzed with 
the logging functions and `plot`ted.    

# Example
```julia
julia> pool = logbforeach(x -> println((x,Threads.threadid())), 1:8);
(1, 2)
(3, 3)
(6, 4)
(4, 3)
(2, 2)
(7, 4)
(5, 3)
(8, 4)

julia> plot(pool)
```
Note that the execution order is not guaranteed, and that the primary thread 
is not used.
"""
function logbforeach(fn, itrs...)
    pool = LoggedStaticPool(2)
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool
end


"""
    logqforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads, using a queued scheduling strategy appropriate for nonuniform
task durations.

# Example
```julia
julia> pool = logqforeach(x -> println((x,Threads.threadid())), 1:8);
(2, 4)
(3, 3)
(4, 2)
(5, 4)
(6, 3)
(7, 2)
(8, 4)
(1, 1)

julia> plot(pool)
```
Note that the execution order is not guaranteed, and that the primary thread 
is used.  Returns a logged pool that can be analyzed with the logging functions 
and `plot`ted.
"""
function logqforeach(fn, itrs...)
    pool = LoggedQueuePool()
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool
end


"""
    logqbforeach(fn, itrs...)

Mimics `Base.foreach`, but launches the function evaluations onto all available 
threads except the primary, using a queued scheduling strategy appropriate for 
nonuniform task durations.  Returns a logged pool that can be analyzed with the 
logging functions and `plot`ted.

# Example
```julia
julia> pool = logqbforeach(x -> println((x,Threads.threadid())), 1:8);
(2, 2)
(1, 3)
(3, 4)
(4, 2)
(5, 3)
(6, 4)
(7, 2)
(8, 3)

julia> plot(pool)
```
Note that the execution order is not guaranteed, and that the primary thread 
is not used.
"""
function logqbforeach(fn, itrs...)
    pool = LoggedQueuePool(2)
    tforeach(x->fn(x...), pool, zip(itrs...))
    close(pool)
    return pool
end
