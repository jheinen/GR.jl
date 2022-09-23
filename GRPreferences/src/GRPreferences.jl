module GRPreferences
    using Preferences

    const os = if Sys.KERNEL === :NT
        :Windows
    else
        Sys.KERNEL
    end

    binary  = Ref{Union{Nothing,String}}()
    grdir   = Ref{Union{Nothing,String}}()
    gksqt   = Ref{Union{Nothing,String}}()
    libGR   = Ref{Union{Nothing,String}}()
    libGR3  = Ref{Union{Nothing,String}}()
    libGRM  = Ref{Union{Nothing,String}}()
    libpath = Ref{Union{Nothing,String}}()

    lib_path(grdir::Nothing, lib) = lib
    lib_path(grdir::AbstractString, lib) =
        if os === :Windows
            joinpath(grdir, "bin", lib)
        elseif os === :Darwin
            joinpath(grdir, "lib", lib)
        else
            joinpath(grdir, "lib", lib)
        end

    function __init__()
        dn = get(ENV, "GRDIR", nothing)
        binary[]  = @load_preference("binary", isnothing(dn) ? "GR_jll" : "system")
        grdir[]   = @load_preference("grdir", dn)
        gksqt[]   = @load_preference("gksqt")
        libGR[]   = @load_preference("libGR", lib_path(dn, "libGR"))
        libGR3[]  = @load_preference("libGR3", lib_path(dn, "libGR3"))
        libGRM[]  = @load_preference("libGRM", lib_path(dn, "libGRM"))
        libpath[] = @load_preference("libpath")
    end

    function use_system_binary(grdir; export_prefs = false, force = false)
        set_preferences!(GRPreferences,
            "binary" => "system",
            "grdir" => grdir,
            "gksqt" => joinpath(grdir, "bin", "gksqt" * (os === :Windows ? ".exe" : "")),
            "libGR" => lib_path(grdir, "libGR"),
            "libGR3" => lib_path(grdir, "libGR3"),
            "libGRM" => lib_path(grdir, "libGRM"),
            "libpath" => joinpath(grdir, "lib"),
            export_prefs = export_prefs,
            force = force
        )
        return nothing
    end

    function use_jll_binary(; export_prefs = false, force = false)
        set_preferences!(GRPreferences,
            "binary" => "GR_jll",
            "grdir" => nothing,
            "gksqt" => nothing,
            "libGR" => nothing,
            "libGR3" => nothing,
            "libGRM" => nothing,
            "libpath" => nothing,
            export_prefs = export_prefs,
            force = force
        )
        return nothing
    end
end
