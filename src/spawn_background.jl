const AVAILABLE_THREADS = Base.RefValue{Channel{Int}}()

# Somehow, fetch doesn't do a very good job at preserving
# stacktraces. So, we catch any error in spawn_background
# And return it as a CapturedException, and then use checked_fetch to
# rethrow any exception in that case
function checked_fetch(future)
    value = fetch(future)
    value isa Exception && throw(value)
    return value
end

"""
    spawnbg(f)

Spawn work on any available background thread.
Captures any exception thrown in the thread, to give better stacktraces.

You can use `checked_fetch(spawnbg(f))` to rethrow any exception.

    ** Warning ** this doesn't compose with other ways of scheduling threads
    So, one should use `spawn_background` exclusively in each Julia process.
"""
function spawnbg(f)
    # -1, because we don't spawn on foreground thread 1
    nbackground = Threads.nthreads() - 1
    if nbackground == 0
        # we don't run in threaded mode, so we just run things async
        # to not block forever
        @warn("No threads available, running in foreground thread")
        return @async try
            return f()
        catch e
            # If we don't do this, we get pretty bad stack traces... not sure why!?
            return CapturedException(e, Base.catch_backtrace())
        end
    end
    # Initialize dynamically, could also do this in __init__ but it's nice to keep things in one place
    if !isassigned(AVAILABLE_THREADS)
        # Allocate a Channel with n background threads
        c = Channel{Int}(nbackground)
        AVAILABLE_THREADS[] = c
        # fill queue with available threads
        foreach(i -> put!(c, i + 1), 1:nbackground)
    end
    # take the next free thread... Will block/wait until a thread becomes free
    thread_id = take!(AVAILABLE_THREADS[])

    return ThreadPools.@tspawnat thread_id begin
        try
            return f()
        catch e
            # If we don't do this, we get pretty bad stack traces...
            # not sure why something so basic just doesn't work well \_(ツ)_/¯
            return CapturedException(e, Base.catch_backtrace())
        finally
            # Make thread available again after work is done!
            put!(AVAILABLE_THREADS[], thread_id)
        end
    end
end
