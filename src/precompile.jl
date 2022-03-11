
macro warnpcfail(ex::Expr)
    modl = __module__
    file = __source__.file === nothing ? "?" : String(__source__.file)
    line = __source__.line
    quote
        $(esc(ex)) || @warn """precompile directive
     $($(Expr(:quote, ex)))
 failed. Please report an issue in $($modl) (after checking for duplicates) or remove this directive.""" _file=$file _line=$line
    end
end


function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @warnpcfail precompile(init,(Bool,))
    @warnpcfail precompile(ispluto,())
    @warnpcfail precompile(isvscode,())
    @warnpcfail precompile(isatom,())
    @warnpcfail precompile(updatews,())

    @warnpcfail precompile(polyline, (Vector{Float64}, Vector{Float64}))
    @warnpcfail precompile(axes, (Float64, Float64, Int64, Int64, Int64, Int64, Float64))

    @warnpcfail precompile(get_func_ptr, (Base.RefValue{Ptr{Nothing}},LibGR_Ptrs, Symbol) )
    @warnpcfail precompile(get_func_ptr, (Base.RefValue{Ptr{Nothing}},LibGRM_Ptrs, Symbol) )
    @warnpcfail precompile(get_func_ptr, (Base.RefValue{Ptr{Nothing}},LibGR3_Ptrs, Symbol) )
    @warnpcfail precompile(libGR_ptr, (Symbol,))
    @warnpcfail precompile(libGRM_ptr, (Symbol,))
    @warnpcfail precompile(libGR3_ptr, (Symbol,))
    @warnpcfail precompile(load_libs, (Bool,))
end