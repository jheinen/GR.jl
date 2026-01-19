module GRM

import GR


mutable struct ArgsT
    ptr::Ptr{Nothing}
    deleted::Bool  # could also be named _is_child, analogous to python-gr
end

function _args_delete(args::ArgsT)
    if args.deleted
        return
    end
    args.deleted = true
    @ccall $(GR.libGRM_ptr(:grm_args_delete))(
        args.ptr::Ptr{Nothing}
    )::Nothing
end

function args_new()
    handle = ccall(GR.libGRM_ptr(:grm_args_new),
                   Ptr{Nothing},
                   ()
                   )

    return finalizer(_args_delete, ArgsT(handle, false))
end

function args_clear(args::ArgsT)
    ccall(GR.libGRM_ptr(:grm_args_clear),
          Nothing,
          (Ptr{Nothing},),
          args.ptr)
end

# need to use @ccall, as conventional ccall does not support differeing variadic argument types
# TODO: Missing types: Complex format "cC"

function args_push(args::ArgsT, key::AbstractString, value::AbstractString)
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "s"::Cstring ;
        value::Cstring
    )::Nothing
end

function args_push(args::ArgsT, key::AbstractString, values::Array{T, 1}) where T <: AbstractString
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "nS"::Cstring ;
        length(values)::Cint,
        values::Ptr{Ptr{UInt8}}
    )::Nothing
end

# Ints
function args_push(args::ArgsT, key::AbstractString, value::Int32)
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "i"::Cstring ;
        value::Cint
    )::Nothing
end

function args_push(args::ArgsT, key::AbstractString, values::Array{Int32, 1})
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "nI"::Cstring ;
        length(values)::Cint,
        values::Ptr{Cint}
    )::Nothing
end

# Doubles
function args_push(args::ArgsT, key::AbstractString, value::Float64)
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "d"::Cstring ;
        value::Cdouble
    )::Nothing
end

function args_push(args::ArgsT, key::AbstractString, values::Array{Float64, 1})
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "nD"::Cstring ;
        length(values)::Cint,
        values::Ptr{Cdouble}
    )::Nothing
end

# ArgumentContainer
function args_push(args::ArgsT, key::AbstractString, value::ArgsT)
    if value.deleted
        throw(ArgumentError("Argument container is already consumed or deleted!"))
    end
    value.deleted = true

    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "a"::Cstring ;
        value.ptr::Ptr{Nothing}
    )::Nothing
end

function args_push(args::ArgsT, key::AbstractString, values::Array{ArgsT, 1})
    for val in values
        if val.deleted
            throw(ArgumentError("Argument container is already consumed or deleted!"))
        end
    end
    for val in values
        val.deleted = true
    end

    values = collect(a.ptr for a in values)
    @ccall $(GR.libGRM_ptr(:grm_args_push))(
        args.ptr::Ptr{Nothing},
        key::Cstring,
        "nA"::Cstring ;
        length(values)::Cint,
        values::Ptr{Ptr{Nothing}}
    )::Nothing
end

# Support for matrices for ints and doubles
function args_push(args::ArgsT, key::AbstractString, values::Array{T, 2}) where {T<:Union{Int32, Float64}}
    values = permutedims(values)
    args_push(args, key, reshape(values, (:)))
    args_push(args, key * "_dims", Int32[i for i in size(values)])
end

# convenience function for args[key] = value
Base.setindex!(args::ArgsT, value::T, key::AbstractString) where {T} = args_push(args, key, value)


function args_remove(args::ArgsT, key::AbstractString)
    ccall(GR.libGRM_ptr(:grm_args_remove),
          Nothing,
          (Ptr{Nothing}, Cstring),
          args.ptr, key)
end

Base.delete!(args::ArgsT, key::AbstractString) = args_remove(args, key)

function args_contains(args::ArgsT, key::AbstractString)
    ccall(GR.libGRM_ptr(:grm_args_contains),
          Cint,
          (Ptr{Nothing}, Cstring),
          args.ptr, key) == 1
end

Base.haskey(args::ArgsT, key::AbstractString) = args_contains(args, key)

function dump_html(plotId::AbstractString)
    ret = ccall(GR.libGRM_ptr(:grm_dump_html),
          Cstring,
          (Cstring,),
          plotId
          )
    HTML(unsafe_string(ret))
end

function dump_html(plotId::AbstractString, args::ArgsT)
    ret = ccall(GR.libGRM_ptr(:grm_dump_html_args),
          Cstring,
          (Cstring, Ptr{Nothing}),
          plotId, args.ptr
          )
    HTML(unsafe_string(ret))
end
end
