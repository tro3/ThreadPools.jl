using Pkg
Pkg.activate("..")
using Documenter, ThreadPools

push!(LOAD_PATH,"../src/")

makedocs(sitename="ThreadPool Documentation")
cp("src/img", "build/img", force=true)
