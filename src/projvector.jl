using Base: @propagate_inbounds

abstract type AbstractConvexSet{T<:AbstractFloat} end

struct ProjectableVector{T<:AbstractFloat} <: AbstractVector{T}

    #contiguous array of source data
    data::Vector{T}
    #array of data views of type Vector{T}, with indexing of
    #each view assumed to be over a contiguous range
    views::Array{SubArray{T,1,Vector{T},Tuple{UnitRange{Int64}},true}}
    projectsto::AbstractConvexSet{T}   #sets that generated the views

    #constructor (composite set)
    function ProjectableVector{T}(x::Vector{T},C::CompositeConvexSet{T}) where{T}

        #check for compatibility of vector to be split
        #and sum of all of the cone sizes
        @assert sum(set->set.dim,C.sets) == length(x)

        #I want an array of views. The actual type
        #of a view is convoluted, so just make one
        #and test it directly.  Use 'similar' in case x
        #is length zero for some reason
        vtype = typeof(view(similar(x,1),1:1))
        views = Array{vtype}(undef,num_subsets(C))

        # loop over the sets and create views
        sidx = 0
        for i = eachindex(C.sets)
            rng = (sidx+1):(sidx + C.sets[i].dim)
            views[i] = view(x,rng)
            sidx += C.sets[i].dim
        end
        return new(x,views,C)
    end
    #constructor (non-composite)
    function ProjectableVector{T}(x::Vector{T},C::AbstractConvexSet{T}) where{T}
        views = [view(x,:)]
        return new(x,views,C)
    end
end

ProjectableVector(x::Vector{T},C) where{T} = ProjectableVector{T}(x,C)

Base.size(A::ProjectableVector) = size(A.data)
Base.length(A::ProjectableVector) = length(A.data)
Base.IndexStyle(::Type{<:ProjectableVector}) = IndexLinear()
@propagate_inbounds Base.getindex(A::ProjectableVector, idx::Int) = getindex(A.data,idx)
@propagate_inbounds Base.setindex!(A::ProjectableVector, val, idx::Int) = setindex!(A.data,val,idx)

Base.iterate(A::ProjectableVector) = iterate(A.data)
Base.iterate(A::ProjectableVector,state) = iterate(A.data,state)
Base.firstindex(A::ProjectableVector) = 1
Base.lastindex(A::ProjectableVector)  = length(A.data)

Base.showarg(io::IO, A::ProjectableVector, toplevel) = print(io, typeof(A))
