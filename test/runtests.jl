
let cmd = `$(Base.julia_cmd()) --depwarn=error --startup-file=no runtests_exec.jl`
    for test_nthreads in sort(collect(Set((1, 2, Threads.nthreads())))) # run once to try single-threaded mode, then try a couple times to trigger bad races
        new_env = copy(ENV)
        new_env["JULIA_NUM_THREADS"] = string(test_nthreads)
        println("\n# Threads = $test_nthreads")
        run(pipeline(setenv(cmd, new_env), stdout = stdout, stderr = stderr))
    end
end
