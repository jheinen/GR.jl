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

"""
    load_libs(always = false)

    Load shared GR libraries from either GR_jll or from GR tarball.
    always is a boolean flag that is passed through to 
"""
function load_libs(always::Bool = false)
    if gr_provider[] == "BinaryBuilder"
        try
            @eval GR import GR_jll
            libGR_handle[] = GR_jll.libGR_handle
            libGR3_handle[] = GR_jll.libGR3_handle
            libGRM_handle[] = GR_jll.libGRM_handle
            grdir[] = joinpath(dirname(GR_jll.libGR_path), "..")
        catch err
            @error "Error importing GR_jll:" err
            ENV["GRDIR"] = ""
            depsfile_succeeded[] = false
            __init__()
            load_libs()
            return
        end
    else
        # Global grdir should be set in __init__

        flag = occursin("site-packages", grdir[])
        loadpath = grdir[]
        if flag
            ENV["GKS_FONTPATH"] = grdir[]
        elseif os != :Windows
            loadpath = joinpath(loadpath, "lib")
        else
            loadpath = joinpath(loadpath, "bin")
        end
        push!(Base.DL_LOAD_PATH, loadpath)

        libGR_handle[] = Libdl.dlopen(libGR)
        libGR3_handle[] = Libdl.dlopen(libGR3)
        libGRM_handle[] = Libdl.dlopen(libGRM)
    end
    @debug "Library handles" libGR_handle[] libGR3_handle[] libGRM_handle[]
    
    libs_loaded[] = true

    check_env[] = true
    init(always)
end

function get_func_ptr(handle::Ref{Ptr{Nothing}}, ptrs::Union{LibGR_Ptrs, LibGRM_Ptrs, LibGR3_Ptrs}, func::Symbol, loaded=libs_loaded[])
    if !loaded
        load_libs(true)
    end
    s = getfield(ptrs, func)
    if s == C_NULL
        s = Libdl.dlsym(handle[], func)
        setfield!(ptrs, func, s)
    end
    return getfield(ptrs,func)
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
precompile(load_libs, (Bool,))