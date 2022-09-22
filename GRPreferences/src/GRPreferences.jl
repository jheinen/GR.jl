module GRPreferences
    using Preferences

    const os = if Sys.KERNEL === :NT
        :Windows
    else
        Sys.KERNEL
    end

    const binary = @load_preference("binary", "GR_jll")
    const grdir = @load_preference("grdir", nothing)
    const gksqt = @load_preference("gksqt", nothing)
    const libGR = @load_preference("libGR", "libGR")
    const libGR3 = @load_preference("libGR3", "libGR3")
    const libGRM = @load_preference("libGRM", "libGRM")
    const libpath = @load_preference("libpath", nothing)

    function use_system_binary(grdir; export_prefs = false, force = false)
        loadpath = if os === :Windows
            joinpath(grdir, "bin")
        elseif os === :Darwin
            joinpath(grdir, "lib")
        else
            joinpath(grdir, "lib")
        end
        @assert isdir(loadpath)
        set_preferences!(GRPreferences,
            "binary" => "system",
            "grdir" => grdir,
            "gksqt" => joinpath(grdir, "bin", "gksqt" * (os === :Windows ? ".exe" : "")),
            "libGR" => joinpath(loadpath, "libGR"),
            "libGR3" => joinpath(loadpath, "libGR3"),
            "libGRM" => joinpath(loadpath, "libGRM"),
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
