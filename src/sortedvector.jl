struct SortedVector{T} <: AbstractVector{T}
    v::Vector{T}
    SortedVector{T}() where {T} = new(T[])
    SortedVector(v) = new{eltype(v)}(sort(v))
end

Base.insert!(a::SortedVector, x) = insert!(a.v, searchsortedfirst(a.v, x), x)

function Base.delete!(a::SortedVector, x)
    r = searchsorted(a.v, x)
    isempty(r) || deleteat!(a.v, first(r))
end

Base.getindex(a::SortedVector, i) = a.v[i]

Base.length(a::SortedVector) = length(a.v)
Base.size(a::SortedVector) = (length(a),)
Base.IndexStyle(::Type{SortedVector}) = IndexLinear()
