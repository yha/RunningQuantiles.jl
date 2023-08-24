# RunningQuantiles.jl

*Reasonably fast running quantiles with NaN handling*

## API
```julia
result = running_quantile(v, p, w, nan_mode=SkipNaNs())
```
computes the running `p`-th quantile of `v` with window `w`, where `w` is an odd window length, or a range of offsets. 
Specifically, 
 - if `w` is a `AbstractUnitRange`, `result[i]` is the `p`-th quantile of `v[(i .+ w) ∩ eachindex(v)]`, where `NaN`s are handled according to `nan_mode`:
   - `nan_mode==SkipNaN()`: `NaN` values are ignored; quantile is computed over non-`NaN`s
   - `nan_mode==PropagateNaNs()`: the result is `NaN` whenever the input window contains `NaN`
   - `nan_mode==ErrOnNaN()`: an error is raise if at least one input window contains `NaN`
 - if `w` is an odd integer, a centered window of length `w` is used, namely `-w÷2:w÷2`

```julia
running_median(v, w, nan_mode=SkipNaNs())
```
computes the running median, i.e. 1/2-th quantile, as above.

## Alternatives and benchmakrs

These two packages also implement running quantiles/medians:
- [SortFilters.jl](https://github.com/sairus7/SortFilters.jl) is faster for small window sizes but the output is garbage when `NaN`s are present.
- [FastRunningMedian.jl](https://github.com/Firionus/FastRunningMedian.jl) is faster for all window size, but only supports median, rather than arbitrary quantiles. It also offers more options for handling of edges.

These package handle the edges and the correspondence of input to output indices differently; please refer to their respective documentation for details.

The most versatile alternative, in terms of options for edge padding and handling of `NaN` values, is probably [ImageFiltering.mapwindow](https://github.com/JuliaImages/ImageFiltering.jl). But it is not specialized for quantiles, and is therefore a *much* slower option.

Benchmarks for running median on a random vector of length `100_000`:
![RunningQuantiles benchmarks](https://user-images.githubusercontent.com/4170948/176232529-91b9b282-27c1-43b8-930a-ab8b4d8b0a51.png)


Shaded areas indicate standard deviation. The input vector has no `NaN`s. Performance of this package in the presence of `NaN`s is generally faster, roughly proportional to the number of non-`NaN`s (the other two packages do not handle `NaN` values correctly).

## Examples

```julia
julia> v = [1:3; fill(NaN,3); 1:5]
11-element Vector{Float64}:
   1.0
   2.0
   3.0
 NaN
 NaN
 NaN
   1.0
   2.0
   3.0
   4.0
   5.0

julia> running_median(v, 3)
11-element Vector{Float64}:
   1.5
   2.0
   2.5
   3.0
 NaN
   1.0
   1.5
   2.0
   3.0
   4.0
   4.5

julia> running_median(v, 3, PropagateNaNs())
11-element Vector{Float64}:
   1.5
   2.0
 NaN
 NaN
 NaN
 NaN
 NaN
   2.0
   3.0
   4.0
   4.5

julia> running_median(v, -3:5) # specifying a non-centered window
11-element Vector{Float64}:
 2.0
 1.5
 2.0
 2.0
 2.5
 3.0
 3.0
 3.0
 3.0
 3.0
 3.5
 ```
