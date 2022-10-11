module GRPreferences
    using Preferences
    try
        import GR_jll
    catch err
        @debug "import GR_jll failed" err
    end

    const grdir   = Ref{Union{Nothing,String}}()
    const gksqt   = Ref{Union{Nothing,String}}()
    const libGR   = Ref{Union{Nothing,String}}()
    const libGR3  = Ref{Union{Nothing,String}}()
    const libGRM  = Ref{Union{Nothing,String}}()
    const libGKS  = Ref{Union{Nothing,String}}()
    const libpath = Ref{Union{Nothing,String}}()

    lib_path(grdir, lib) =
        if Sys.iswindows()
            joinpath(grdir, "bin", lib)
        else
            joinpath(grdir, "lib", lib)
        end

    gksqt_path(grdir) = 
        if Sys.iswindows()
            joinpath(grdir, "bin", "gksqt.exe")
        elseif Sys.isapple()
            joinpath(grdir, "Applications", "gksqt.app", "Contents", "MacOS", "gksqt")
        else
            joinpath(grdir, "bin", "gksqt")
        end

    function __init__()
        binary = @load_preference("binary", haskey(ENV, "GRDIR") ? "system" : "GR_jll")
        if binary == "GR_jll"
            grdir[]   = GR_jll.find_artifact_dir()
            gksqt[]   = GR_jll.gksqt_path
            libGR[]   = GR_jll.libGR
            libGR3[]  = GR_jll.libGR3
            libGRM[]  = GR_jll.libGRM
            libGKS[]  = GR_jll.libGKS
            libpath[] = GR_jll.LIBPATH[]
        elseif binary == "system"
            grdir[]   = haskey(ENV, "GRDIR") ? ENV["GRDIR"] : @load_preference("grdir")
            gksqt[]   = gksqt_path(grdir[])
            libGR[]   = lib_path(grdir[], "libGR")
            libGR3[]  = lib_path(grdir[], "libGR3")
            libGRM[]  = lib_path(grdir[], "libGRM")
            libGKS[]  = lib_path(grdir[], "libGKS")
            libpath[] = joinpath(grdir[], "lib")
        else
            error("Unknown GR binary: $binary")
        end
    end

    use_system_binary(grdir; export_prefs = false, force = false) = set_preferences!(
        GRPreferences,
        "binary" => "system",
        "grdir" => grdir,
        export_prefs = export_prefs,
        force = force
    )

    use_jll_binary(; export_prefs = false, force = false) = set_preferences!(
        GRPreferences,
        "binary" => "GR_jll",
        "grdir" => nothing,
        export_prefs = export_prefs,
        force = force
    )
end
