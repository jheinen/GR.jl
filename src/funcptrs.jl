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

@create_func_ptr_struct LibGR_Ptrs include("libgr_syms.jl")
@create_func_ptr_struct LibGRM_Ptrs include("libgrm_syms.jl")
@create_func_ptr_struct LibGR3_Ptrs include("libgr3_syms.jl")

const libGR_ptrs = LibGR_Ptrs()
const libGRM_ptrs = LibGRM_Ptrs()
const libGR3_ptrs = LibGR3_Ptrs()

function get_func_ptr(handle::Ptr{Nothing}, ptrs::Union{LibGR_Ptrs, LibGRM_Ptrs, LibGR3_Ptrs}, func::Symbol)
    s = getfield(ptrs, func)
    if s == C_NULL
        s = Libdl.dlsym(handle, func)
        setfield!(ptrs, func, s)
    end
    return getfield(ptrs,func)
end

libGR_ptr(func) = get_func_ptr(libGR_handle, libGR_ptrs, func)
libGRM_ptr(func) = get_func_ptr(libGRM_handle, libGRM_ptrs, func)
libGR3_ptr(func) = get_func_ptr(libGR3_handle, libGR3_ptrs, func)
