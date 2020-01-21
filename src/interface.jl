
abstract type AbstractThreadPool end

_detect_type(fn, itr) = eltype(map(fn, empty(itr)))
_detect_type(fn, itrs::Tuple) = eltype(map(fn, [empty(x) for x in itrs]...))

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

pmap(fn::Function, pool, itr) = pmap(pool, fn, itr)
pmap(pool, fn::Function, itrs...) = pmap(pool, (x) -> fn(x...), zip(itrs...))
pmap(fn::Function, pool, itrs...) = pmap(pool, (x) -> fn(x...), zip(itrs...))


function pwith(fn::Function, pool)
    fn(pool)
    close(pool)
    pool
end


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

function Base.close(pool::AbstractThreadPool)
    nothing
end
