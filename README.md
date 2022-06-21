# RunningQuantiles.jl

*Reasonably fast running quantiles with NaN handling*

Examples:

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
