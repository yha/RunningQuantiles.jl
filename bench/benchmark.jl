using BenchmarkTools

using RunningQuantiles
import RollingFunctions
import FastRunningMedian
import SortFilters
using DataStructures

function make_v(p_nan = 0.1, n=10_000)
    v = rand(n)
    v[rand(n) .< p_nan] .= NaN
    v
end

benches = OrderedDict(
    "FastRunningMedian" => (v,w) -> FastRunningMedian.running_median(v, w),
    "SortFilters"       => (v,w) -> SortFilters.movsort(v, w, 0.5),
    "RunningQuantiles"  => (v,w) -> running_median(v, w),
)

function bench(f,k,n,w)
    @info "Benchmarking $k, w=$w"
    @benchmark $f(v,$w) setup=(v=make_v(0,$n)) #seconds=0.5
    # v = make_v(0,n)
    # t = @elapsed f(v,w)
    # (; times = [t])
end


n = 100_000
w = [3,11,31,101,301,1001,3001,10_001]
b = OrderedDict(k => [bench(f,k,n,w) for w in w]
                for (k,f) in benches)


##

using Plots
using StatsBase

function plot_benchmarks!(x, benchmarks; kwargs...)
    times = [b.times for b in benchmarks] ./ 1e9
    #errs = @. std(times) / √length(times)
    plot!(x, mean.(times); 
                ylabel = "time [s]",
                xlabel = "window length",
                ribbon=std.(times), 
                #yerr=errs, 
                #yerr=std.(times),
                kwargs...)
end
plot(title="running median, n=$n", legend=:topleft)
for (k,v) in b
    plot_benchmarks!(w, v; label=k, xscale=:log10, yscale=:log10, lw=3, m=true)
end
#current()
savefig("RunningQuantiles benchmarks.png")


