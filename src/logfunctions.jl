
logerror() = throw(SystemError("Logging ThreadPool invoked with nthreads=1.  Please use single-threaded version"))


"""
    ThreadPools.logbgforeach(fn, io, itrs...) -> Nothing

Mimics [`bgforeach`](@ref), but with a log that can be analyzed with 
[`readlog`](@ref).  If `io` is a string, a file will be opened with
that name and used as the log.  At the end of the loop `io` is closed.

!! note
    This function cannot be used with Threads.nthreads() == 1, and will
    throw an error if this is tried.
"""
logbgforeach(fn, io::IO, itr)     = Threads.nthreads() == 1 ? logerror() : _poolforeach(fn, LoggingThreadPool(io), (itr,))
logbgforeach(fn, io::IO, itrs...) = Threads.nthreads() == 1 ? logerror() : _poolforeach(fn, LoggingThreadPool(io), itrs)

function logbgforeach(fn, fname::String, itrs)
    Threads.nthreads() == 1 && logerror()
    io = open(fname, "w")
    r = logbgforeach(fn, io, itrs)
    close(io)
    return r
end


"""
    ThreadPools.logfgforeach(fn, io, itrs...) -> Nothing

Mimics [`fgforeach`](@ref), but with a log that can be analyzed with 
[`readlog`](@ref).  If `io` is a string, a file will be opened with
that name and used as the log.  At the end of the loop `io` is closed.

!! note
    This function cannot be used with Threads.nthreads() == 1, and will
    throw an error if this is tried.
"""
logfgforeach(fn, io::IO, itr)     = Threads.nthreads() == 1 ? logerror() : _poolforeach(fn, LoggingThreadPool(io, true), (itr,))
logfgforeach(fn, io::IO, itrs...) = Threads.nthreads() == 1 ? logerror() : _poolforeach(fn, LoggingThreadPool(io, true), itrs)

function logfgforeach(fn, fname::String, itrs)
    Threads.nthreads() == 1 && logerror()
    io = open(fname, "w")
    r = logfgforeach(fn, io, itrs)
    close(io)
    return r
end


"""
    ThreadPools.logbgmap(fn, io, itrs...) -> Nothing

Mimics [`bgmap`](@ref), but with a log that can be analyzed with 
[`readlog`](@ref).  If `io` is a string, a file will be opened with
that name and used as the log.  At the end of the loop `io` is closed.

!! note
    This function cannot be used with Threads.nthreads() == 1, and will
    throw an error if this is tried.
"""
logbgmap(fn, io::IO, itr)::Vector{_detect_type(fn, itr)}      = Threads.nthreads() == 1 ? logerror() : _poolmap(fn, LoggingThreadPool(io), (itr,))
logbgmap(fn, io::IO, itrs...)::Vector{_detect_type(fn, itrs)} = Threads.nthreads() == 1 ? logerror() : _poolmap(fn, LoggingThreadPool(io), itrs)

function logbgmap(fn, fname::String, itrs)
    Threads.nthreads() == 1 && logerror()
    io = open(fname, "w")
    r = logbgmap(fn, io, itrs)
    close(io)
    return r
end


"""
    ThreadPools.logfgmap(fn, io, itrs...) -> Nothing

Mimics [`fgmap`](@ref), but with a log that can be analyzed with 
[`readlog`](@ref).  If `io` is a string, a file will be opened with
that name and used as the log.  At the end of the loop `io` is closed.

!! note
    This function cannot be used with Threads.nthreads() == 1, and will
    throw an error if this is tried.
"""
logfgmap(fn, io::IO, itr)::Vector{_detect_type(fn, itr)}      = Threads.nthreads() == 1 ? logerror() : _poolmap(fn, LoggingThreadPool(io, true), (itr,))
logfgmap(fn, io::IO, itrs...)::Vector{_detect_type(fn, itrs)} = Threads.nthreads() == 1 ? logerror() : _poolmap(fn, LoggingThreadPool(io, true), itrs)

function logfgmap(fn, fname::String, itrs)
    Threads.nthreads() == 1 && logerror()
    io = open(fname, "w")
    r = logfgmap(fn, io, itrs)
    close(io)
    return r
end


"""
    ThreadPools.@logbgthreads io

Mimics [`@bgthreads`](@ref), but with a log that can be analyzed with 
[`readlog`](@ref).  If `io` is a string, a file will be opened with
that name and used as the log.  At the end of the loop `io` is closed.

!! note
    This function cannot be used with Threads.nthreads() == 1, and will
    throw an error if this is tried.
"""
macro logbgthreads(io, args...)
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
                logbgforeach($(esc(io)), $(esc(range))) do $(esc(index))
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
    ThreadPools.@logfgthreads io

Mimics [`@fgthreads`](@ref), but with a log that can be analyzed with 
[`readlog`](@ref).  If `io` is a string, a file will be opened with
that name and used as the log.  At the end of the loop `io` is closed.

!! note
    This function cannot be used with Threads.nthreads() == 1, and will
    throw an error if this is tried.
"""
macro logfgthreads(io, args...)
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
                logfgforeach($(esc(io)), $(esc(range))) do $(esc(index))
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