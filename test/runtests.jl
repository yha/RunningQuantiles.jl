using Test
using RunningQuantiles
using ImageFiltering
using NaNMath, NaNStatistics
using Statistics

const ⩦ = isequal

@testset "basic running_median examples" begin
    @test running_median(1:5,  0:0) == running_median(1:5, 1) == 1:5
    @test running_median(1:5, -1:1) == running_median(1:5, 3) == [1.5, 2.0, 3.0, 4.0, 4.5]
    @test running_median(1:5, -2:2) == running_median(1:5, 5) == [2.0, 2.5, 3.0, 3.5, 4.0]
    @test running_median(1:5, -3:3) == running_median(1:5, 7) == [2.5, 3.0, 3.0, 3.0, 3.5]
    @test running_median(1:5, -4:4) == running_median(1:5, 9) == [3.0, 3.0, 3.0, 3.0, 3.0]
    @test running_median(1:5, -500:500) == running_median(1:5, 1001) == [3.0, 3.0, 3.0, 3.0, 3.0]

    @test running_quantile(1:5, 1/4, 5) == [1.5, 1.75, 2.0, 2.75, 3.5]
    @test running_quantile(1:5, 3/4, 5) == [2.5, 3.25, 4.0, 4.25, 4.5]

    @test running_median(1:5,   1:2 ) ⩦ [2.5, 3.5, 4.5, 5.0, NaN]
    @test running_median(1:5,  -2:-1) ⩦ [NaN, 1.0, 1.5, 2.5, 3.5]
    @test running_median(1:5,   1:10) ⩦ [3.5, 4.0, 4.5, 5.0, NaN]
    @test running_median(1:5, -10:-1) ⩦ [NaN, 1.0, 1.5, 2.0, 2.5]
    @test running_median(1:5,  -6:-5) ⩦ fill(NaN,5)
    @test running_median(1:5,   5:6 ) ⩦ fill(NaN,5)
    @test running_median(1:5,   1:0 ) ⩦ fill(NaN,5)
end

@testset "errors" begin
    @testset "even $even $p" for even in 0:2:20, p in 0:0.1:1
        @test_throws ArgumentError running_median(1:5, even)
        @test_throws ArgumentError running_quantile(1:5, p, even)
    end
    @testset "negative $negative $p" for negative in [-(10 .^ 2:6); -10:-1], p in 0:0.1:1
        @test_throws ArgumentError running_median(1:5, negative)
        @test_throws ArgumentError running_quantile(1:5, p, negative)
    end
    @testset "p = $p ∉ [0,1]" for w in 1:2:9, p in [-100,-1,-1e-6,1+1e-6, 1.1, 10, 100]
        @test_throws ArgumentError running_quantile(1:5, p, w)
    end
end

@testset "running_median NaN handling" begin
    v = [1,2,3,4,NaN,6,7,8,NaN]
    @test running_median(v,  0:0) ⩦ running_median(v, 0:0, SkipNaNs()) ⩦ v
    @test running_median(v, -1:1) ⩦ running_median(v, -1:1, SkipNaNs()) ⩦ [1.5, 2.0, 3.0, 3.5, 5.0, 6.5, 7.0, 7.5, 8.0]
    @test running_median(v,  0:0,   PropagateNaNs())  ⩦ v
    @test running_median(v, -1:1,   PropagateNaNs())  ⩦ [1.5, 2.0, 3.0, NaN, NaN, NaN, 7.0, NaN, NaN]
    @test running_median(v,  3:5,   PropagateNaNs())  ⩦ [NaN, NaN, 7.0, NaN, NaN, NaN, NaN, NaN, NaN]
    @test running_median(v,  9:10,  PropagateNaNs())  ⩦ fill(NaN,9)
    @test running_median(v,  10:10, ErrOnNaN())       ⩦ fill(NaN,9)
    @test_throws Exception running_median(v,  0:0, ErrOnNaN())
end

# Naive implementations of running quantile with NaN handling, with the border behavior of this package
run_q_skip(v,p,w) = mapwindow(v, w; border=Fill(NaN)) do window
    non_nans = filter(!isnan, window)
    isempty(non_nans) ? NaN : quantile(non_nans, p)
end

function run_q_propagate(v,p,w)
    # find a sentinel float value which is not in v, to mark out-of-border elements
    sentinel = maximum(filter(isfinite,v)) * 1.01
    @assert sentinel ∉ v

    p_quantile(window) = any(isnan, window) ? NaN : quantile(filter(!=(sentinel), window), p)

    mapwindow(p_quantile, v, w; border=Fill(sentinel))
end
# possible implementation once `ImageFiltering.mapwindow` supports the `NA` border stye:
#run_q_propagate(v,p,w) = mapwindow(w->quantile(w,p), v, w; border=NA())

@testset "ImageFiltering comparisons" begin
    v = rand(10_000)
    v[rand(length(v)) .< 0.1] .= NaN
    v[5000:6000] .= NaN # at least one full window of NaNs in all tested window sizes

    @testset "mapwindow w=$w" for w in [1:2:11; 21:10:101; 201:200:1001]
        @info "ImageFiltering.mapwindow comparison, w=$w"
        @test running_median(v, w) ⩦ run_q_skip(v, 0.5, w)
        @test running_median(v, w, PropagateNaNs()) ⩦ run_q_propagate(v, 0.5, w)
        @test_throws ErrorException running_median(v, w, ErrOnNaN())
        for p in [0.0, 0.1, 0.25, 0.75, 0.9, 1.0]
            @test running_quantile(v, p, w) ⩦ run_q_skip(v, p, w)
            @test running_quantile(v, p, w, PropagateNaNs()) ⩦ run_q_propagate(v, p, w)
            @test_throws ErrorException running_quantile(v, p, w, ErrOnNaN())
        end
    end
end


# TODO test with OffsetArrays
