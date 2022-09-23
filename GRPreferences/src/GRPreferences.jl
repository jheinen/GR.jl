module GRPreferences
    using Preferences

    const os = Sys.KERNEL === :NT ? :Windows : Sys.KERNEL

    const grdir   = Ref{Union{Nothing,String}}()
    const gksqt   = Ref{Union{Nothing,String}}()
    const libGR   = Ref{Union{Nothing,String}}()
    const libGR3  = Ref{Union{Nothing,String}}()
    const libGRM  = Ref{Union{Nothing,String}}()
    const libpath = Ref{Union{Nothing,String}}()
    const GR_jll  = Ref{Union{Nothing,Module}}()

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
            @eval Main import GR_jll
            GR_jll[]  = Main.GR_jll
            grdir[]   = Base.invokelatest(Main.GR_jll.find_artifact_dir)
            libGR[]   = Main.GR_jll.libGR
            libGR3[]  = Main.GR_jll.libGR3
            libGRM[]  = Main.GR_jll.libGRM
            gksqt[]   = Main.GR_jll.gksqt_path
            libpath[] = Main.GR_jll.LIBPATH[]
        elseif binary == "system"
            GR_jll[]  = nothing
            grdir[]   = haskey(ENV, "GRDIR") ? ENV["GRDIR"] : @load_preference("grdir")
            libGR[]   = lib_path(grdir[], "libGR")
            libGR3[]  = lib_path(grdir[], "libGR3")
            libGRM[]  = lib_path(grdir[], "libGRM")
            gksqt[]   = joinpath(grdir[], "bin", "gksqt" * (os === :Windows ? ".exe" : ""))
            libpath[] = joinpath(grdir[], "lib")
        else
            error("Unknown GR binary: $binary")
        end
    end

    use_system_binary(grdir; export_prefs = false, force = false) =
        set_preferences!(GRPreferences,
            "binary" => "system",
            "grdir" => grdir,
            export_prefs = export_prefs,
            force = force
        )

    use_jll_binary(; export_prefs = false, force = false) =
        set_preferences!(GRPreferences,
            "binary" => "GR_jll",
            "grdir" => nothing,
            export_prefs = export_prefs,
            force = force
        )
end
