module RunningQuantiles

export running_quantile, running_median, SkipNaNs, PropagateNaNs, ErrOnNaN

using SkipLists
using OffsetArrays
using Statistics

include("sortedvector.jl")

abstract type NaNHandling end
struct SkipNaNs <: NaNHandling end
struct PropagateNaNs <: NaNHandling end
struct ErrOnNaN <: NaNHandling end

#_q(v,p) = quantile(v, p; sorted=true)
# using the internal `Statistics._quantile` to skip the check for NaNs in v
_q(v,p) = Statistics._quantile(v, p)
_quantile(::SkipNaNs,      p, non_nans, has_nans) = isempty(non_nans) ? NaN : _q(non_nans,p)
_quantile(::PropagateNaNs, p, non_nans, has_nans) = has_nans || isempty(non_nans) ? NaN : _q(non_nans,p)
_quantile(::ErrOnNaN,      p, non_nans, has_nans) = has_nans ? _nan_error() : isempty(non_nans) ? NaN : _q(non_nans,p)
_nan_error() = error("NaNs encountered in `running_quantile` with `nan_mode=ErrOnNaN`")

make_window(r::AbstractUnitRange) = r
function make_window(winlen::Int)
    winlen > 0 && isodd(winlen) || throw(ArgumentError("Window length must be an odd positive integer."))
    -winlen÷2:winlen÷2
end


"""
    running_median(v, w, nan_mode=SkipNaNs())

Computes the running median of the vector `v` with window `w`, where `w` is an odd window length, or a range of offsets.
See [`running_quantile`](@ref) for details.
"""
function running_median(v, w, nan_mode=SkipNaNs(); buffer = default_buffer(v,0.5,w))
    running_quantile(v, 0.5, w, nan_mode; buffer)
end

"""
    result = running_quantile(v, p, w, nan_mode=SkipNaNs())

Computes the running `p`-th quantile of the vector `v` with window `w`, where `w` is an odd window length, or a range of offsets.
Specifically, 
 - if `w` is a `AbstractUnitRange`, `result[i]` is the `p`-th quantile of `v[(i .+ w) ∩ eachindex(v)]`, where `NaN`s are handled according to `nan_mode`:
   - `nan_mode==SkipNaN()`: `NaN` values are ignored; quantile is computed over non-`NaN`s
   - `nan_mode==PropagateNaNs()`: the result is `NaN` whenever the input window contains `NaN`
   - `nan_mode==ErrOnNaN()`: an error is raise if at least one input window contains `NaN`
 - if `w` is an odd integer, a centered window of length `w` is used, namely `-w÷2:w÷2`
 """
function running_quantile(v, p, w, nan_mode=SkipNaNs(); buffer = default_buffer(v,p,w))
    _running_quantile(v, p, make_window(w), nan_mode; buffer)
end
function _running_quantile(v, p, r::AbstractUnitRange, nan_mode; buffer)
    result = similar(v, float(eltype(v)))
    # wrapping this Int in a `Ref` helps the compiler not create a `Box` 
    # for capturing `nan_count` in the closures below
    nan_count = Ref(0)

    add!(x)    = isnan(x) ? (nan_count[] += 1) : insert!(buffer, x)
    remove!(x) = isnan(x) ? (nan_count[] -= 1) : delete!(buffer, x)
    put_quantile!(i) = (result[i] = _quantile( nan_mode, p, buffer, nan_count[] > 0 ))

    Δ_remove, Δ_add = first(r)-1, last(r)

    put_range    = eachindex(v)::AbstractUnitRange
    add_range    = put_range .- Δ_add
    remove_range = put_range .- Δ_remove

    @assert Δ_remove <= Δ_add
    for i in firstindex(v) - max(Δ_add,0) : lastindex(v) - min(Δ_remove,0)
        i ∈ add_range    && add!(    v[ i + Δ_add ]    )
        i ∈ remove_range && remove!( v[ i + Δ_remove ] )
        i ∈ put_range    && put_quantile!(i)
    end

    result
end

function default_buffer(v,p,w)
    # Heuristics derived from superficial benchmarking.
    # These can probably be improved.
    len = length(make_window(w))
    if len > 6000
        SkipList{eltype(v)}(; node_capacity = round(Int, len/10))
    else
        SortedVector{eltype(v)}()
    end
end

end # module
