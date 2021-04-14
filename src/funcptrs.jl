# Create mutable structs to cache function pointers
macro create_func_ptr_struct(name, syms)
    e = :(mutable struct $name end)
    for s in eval(syms)
        push!(e.args[3].args, :($s::Ptr{Nothing}))
    end
    push!(e.args[3].args, :( 
        $name() = new( fill(C_NULL,length($syms))... )
    ) )
    e
end

include("libgr_syms.jl")
include("libgrm_syms.jl")
include("libgr3_syms.jl")

@create_func_ptr_struct LibGR_Ptrs libGR_syms
@create_func_ptr_struct LibGRM_Ptrs libGRM_syms
@create_func_ptr_struct LibGR3_Ptrs libGR3_syms

const libGR_ptrs = LibGR_Ptrs()
const libGRM_ptrs = LibGRM_Ptrs()
const libGR3_ptrs = LibGR3_Ptrs()

const libs_loaded = Ref(false)

function load_libs()
    if gr_provider[] == "BinaryBuilder"
        libGR_handle[] = GR_jll.libGR_handle
        libGR3_handle[] = GR_jll.libGR3_handle
        libGRM_handle[] = GR_jll.libGRM_handle
    else
        libGR_handle[] = Libdl.dlopen(libGR)
        libGR3_handle[] = Libdl.dlopen(libGR3)
        libGRM_handle[] = Libdl.dlopen(libGRM)
    end
    @debug "Library handles" libGR_handle[] libGR3_handle[] libGRM_handle[]

    libs_loaded[] = true
end

function get_func_ptr(handle::Ref{Ptr{Nothing}}, ptrs::Union{LibGR_Ptrs, LibGRM_Ptrs, LibGR3_Ptrs}, func::Symbol)
    if !libs_loaded[]
        load_libs()
    end
    s = getfield(ptrs, func)
    if s == C_NULL
        s = Libdl.dlsym(handle[], func)
        setfield!(ptrs, func, s)
    end
    return s
end

libGR_ptr(func) = get_func_ptr(libGR_handle, libGR_ptrs, func)
libGRM_ptr(func) = get_func_ptr(libGRM_handle, libGRM_ptrs, func)
libGR3_ptr(func) = get_func_ptr(libGR3_handle, libGR3_ptrs, func)

precompile(get_func_ptr, (Base.RefValue{Ptr{Nothing}},LibGR_Ptrs, Symbol) )
precompile(get_func_ptr, (Base.RefValue{Ptr{Nothing}},LibGRM_Ptrs, Symbol) )
precompile(get_func_ptr, (Base.RefValue{Ptr{Nothing}},LibGR3_Ptrs, Symbol) )
precompile(libGR_ptr, (Symbol,))
precompile(libGRM_ptr, (Symbol,))
precompile(libGR3_ptr, (Symbol,))
precompile(load_libs, ())