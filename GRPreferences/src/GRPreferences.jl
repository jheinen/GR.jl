module GRPreferences
    using Preferences
    try
        import GR_jll
    catch err
        @debug "import GR_jll failed" err
    end

    const os = Sys.KERNEL === :NT ? :Windows : Sys.KERNEL

    const grdir   = Ref{Union{Nothing,String}}()
    const gksqt   = Ref{Union{Nothing,String}}()
    const libGR   = Ref{Union{Nothing,String}}()
    const libGR3  = Ref{Union{Nothing,String}}()
    const libGRM  = Ref{Union{Nothing,String}}()
    const libpath = Ref{Union{Nothing,String}}()

    lib_path(grdir, lib) =
        if os === :Windows
            joinpath(grdir, "bin", lib)
        elseif os === :Darwin
            joinpath(grdir, "lib", lib)
        else
            joinpath(grdir, "lib", lib)
        end

    function __init__()
        binary = @load_preference("binary", haskey(ENV, "GRDIR") ? "system" : "GR_jll")
        if binary == "GR_jll"
            grdir[]   = GR_jll.find_artifact_dir()
            gksqt[]   = GR_jll.gksqt_path
            libGR[]   = GR_jll.libGR
            libGR3[]  = GR_jll.libGR3
            libGRM[]  = GR_jll.libGRM
            libpath[] = GR_jll.LIBPATH[]
        elseif binary == "system"
            grdir[]   = haskey(ENV, "GRDIR") ? ENV["GRDIR"] : @load_preference("grdir")
            gksqt[]   = joinpath(grdir[], "bin", "gksqt" * (os === :Windows ? ".exe" : ""))
            libGR[]   = lib_path(grdir[], "libGR")
            libGR3[]  = lib_path(grdir[], "libGR3")
            libGRM[]  = lib_path(grdir[], "libGRM")
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
