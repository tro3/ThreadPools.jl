
function _pthread_macro(pool, args...)
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
                pool = pwith($(esc(pool))) do p
                    pforeach(p, $(esc(range))) do $(esc(index))
                        $(esc(body))
                    end
                end
                pool
            end
        else
            throw(ArgumentError("nested outer loops are not currently supported by thread macro"))
        end
    else
        throw(ArgumentError("unrecognized argument tothread macro"))
    end
end

macro qthreads(args...) 
    return _pthread_macro(QueuePool(1), args...)
end

macro bthreads(args...) 
    return _pthread_macro(StaticPool(2), args...)
end

macro qbthreads(args...) 
    return _pthread_macro(QueuePool(2), args...)
end

macro logthreads(args...) 
    return _pthread_macro(LoggedStaticPool(1), args...)
end

macro logqthreads(args...) 
    return _pthread_macro(LoggedStaticPool(1), args...)
end

macro logbthreads(args...) 
    return _pthread_macro(LoggedQueuePool(2), args...)
end

macro logqbthreads(args...) 
    return _pthread_macro(LoggedQueuePool(2), args...)
end
