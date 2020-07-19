
@deprecate pmap(fn::Function, itr) tmap(fn::Function, itr)
@deprecate pforeach(fn::Function, itr) tforeach(fn::Function, itr)
@deprecate logpmap(fn::Function, itr) logtmap(fn::Function, itr)
@deprecate logpforeach(fn::Function, itr) logtforeach(fn::Function, itr)


"""
    tmap(fn::Function, itr) -> collection

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
function tmap(fn::Function, itr)
    pool = StaticPool()
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return result
end

"""
    bmap(fn::Function, itr) -> collection

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
function bmap(fn, itr)
    pool = StaticPool(2)
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return result
end

"""
    qmap(fn::Function, itr) -> collection

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
function qmap(fn, itr)
    pool = QueuePool()
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return result
end

"""
    qbmap(fn::Function, itr) -> collection

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
function qbmap(fn, itr)
    pool = QueuePool(2)
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return result
end

"""
    logtmap(fn::Function, itr) -> (pool, collection)

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
function logtmap(fn::Function, itr)
    pool = LoggedStaticPool()
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return pool, result
end

"""
    logbmap(fn::Function, itr) -> (pool, collection)

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
function logbmap(fn, itr)
    pool = LoggedStaticPool(2)
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return pool, result
end

"""
    logqmap(fn::Function, itr) -> (pool, collection)

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
function logqmap(fn, itr)
    pool = LoggedQueuePool()
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return pool, result
end

"""
    logqbmap(fn::Function, itr) -> (pool, collection)

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
function logqbmap(fn, itr)
    pool = LoggedQueuePool(2)
    result::Array{_detect_type(fn, itr), ndims(itr)} = tmap(pool, fn, itr)
    close(pool)
    return pool, result
end


"""
    tforeach(fn::Function, itr)

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
function tforeach(fn::Function, itr)
    pool = StaticPool()
    tforeach(pool, fn, itr)
    close(pool)
    nothing
end


"""
    bforeach(fn::Function, itr)

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
function bforeach(fn, itr)
    pool = StaticPool(2)
    tforeach(pool, fn, itr)
    close(pool)
    nothing
end

"""
    qforeach(fn::Function, itr)

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
function qforeach(fn, itr)
    pool = QueuePool()
    tforeach(pool, fn, itr)
    close(pool)
    nothing
end


"""
    qbforeach(fn::Function, itr)

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
function qbforeach(fn, itr)
    pool = QueuePool(2)
    tforeach(pool, fn, itr)
    close(pool)
    nothing
end



"""
    logtforeach(fn::Function, itr) -> pool

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
function logtforeach(fn::Function, itr)
    pool = LoggedStaticPool()
    tforeach(pool, fn, itr)
    close(pool)
    return pool
end


"""
    logbforeach(fn::Function, itr)

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
function logbforeach(fn, itr)
    pool = LoggedStaticPool(2)
    tforeach(pool, fn, itr)
    close(pool)
    return pool
end


"""
    logqforeach(fn::Function, itr)

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
function logqforeach(fn, itr)
    pool = LoggedQueuePool()
    tforeach(pool, fn, itr)
    close(pool)
    return pool
end


"""
    logqbforeach(fn::Function, itr)

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
function logqbforeach(fn, itr)
    pool = LoggedQueuePool(2)
    tforeach(pool, fn, itr)
    close(pool)
    return pool
end
