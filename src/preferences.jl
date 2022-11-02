module GRPreferences
    using Preferences
    using Artifacts
    using TOML
    try
        import GR_jll
    catch err
        @debug "import GR_jll failed" err
    end
    include("downloader.jl")

    const grdir   = Ref{Union{Nothing,String}}()
    const gksqt   = Ref{Union{Nothing,String}}()
    const libGR   = Ref{Union{Nothing,String}}()
    const libGR3  = Ref{Union{Nothing,String}}()
    const libGRM  = Ref{Union{Nothing,String}}()
    const libGKS  = Ref{Union{Nothing,String}}()
    const libpath = Ref{Union{Nothing,String}}()

    lib_path(grdir::AbstractString, lib::AbstractString) =
        if Sys.iswindows()
            joinpath(grdir, "bin", lib)
        else
            joinpath(grdir, "lib", lib)
        end

    # Default grdir to deps/gr if nothing
    lib_path(grdir::Nothing, lib::AbstractString) =
        lib_path(joinpath(@__DIR__, "..", "deps", "gr"), lib)

    gksqt_path(grdir) = 
        if Sys.iswindows()
            joinpath(grdir, "bin", "gksqt.exe")
        elseif Sys.isapple()
            joinpath(grdir, "Applications", "gksqt.app", "Contents", "MacOS", "gksqt")
        else
            joinpath(grdir, "bin", "gksqt")
        end

    # Default grdir to deps/gr if nothing
    gksqt_path(grdir::Nothing) =
        gksqt_path(joinpath(@__DIR__, "..", "deps", "gr"))

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

    """
        use_system_binary(grdir; export_prefs = false, force = false, override = :depot)

    Use the system binaries located at `grdir`.
    See `Preferences.set_preferences!` for the `export_prefs` and `force` keywords.

    The override keyword can be either:
    * :depot, Override GR_jll using the depot Overrides.toml
    * :project, Override GR_jll using the project Preferences.toml
    * (:depot, :project), Overide GR_jll in both the depot and the project
    """
    function use_system_binary(grdir; export_prefs = false, force = false, override = :depot)
        try
            set_preferences!(
                GRPreferences,
                "binary" => "system",
                "grdir" => grdir,
                export_prefs = export_prefs,
                force = force
            )
        catch err
            if err isa ArgumentError
                throw(ArgumentError("Could not set GR system binary preference. Consider using the `force = true` keyword argument."))
            end
        end
        if override isa Symbol
            override = (override,)
        end
        if :depot in override
            override_depot(grdir)
        end
        if :project in override
            override_project(grdir; force)
        end
        @info "Please restart Julia to change the GR binary configuration."
    end


    """
        use_jll_binary(; export_prefs = false, force = false)

    Use GR_jll in the its standard configuration from BinaryBuilder.org.

    See `Preferences.set_preferences!` for the `export_prefs` and `force` keywords.
    """
    function use_jll_binary(; export_prefs = false, force = false)
        try
            set_preferences!(
                GRPreferences,
                "binary" => "GR_jll",
                "grdir" => nothing,
                export_prefs = export_prefs,
                force = force
            )
        catch err
            if err isa ArgumentError
                throw(ArgumentError("Could not set GR jll binary preference. Consider using the `force = true` keyword argument."))
            end
        end
        unoverride_depot()
        unoverride_project(; force)
        @info "Please restart Julia to change the GR binary configuration."
    end


    """
        use_upstream_binary([install_dir]; export_prefs = false, force = false, override = :depot)

    Download the binaries from https://github.com/sciapp/gr/ and configure GR to use those.

    A directory "gr" will be placed within `install_dir` containing the upstream binaries.
    By default install_dir will be `joinpath(pathof(GR), "deps")`.

    See `use_system_binary` for details.
    """
    function use_upstream_binary(args...; export_prefs = false, force = false, override = :depot)
        grdir = Downloader.download(args...)
        use_system_binary(grdir; export_prefs, force, override)
    end

    """
        get_override_toml_path()

    Get the path the depot's Overrides.toml
    """
    function get_override_toml_path()
        override_toml_path = joinpath(Artifacts.artifacts_dirs()[1], "Overrides.toml")
    end

    """
        override_depot([grdir])

    Override GR_jll in the DEPOT_PATH[1]/artifacts/Overrides.toml with `grdir`.
    """
    function override_depot(grdir = grdir[])
        override_toml_path = get_override_toml_path()
        override_dict = if isfile(override_toml_path)
            TOML.parsefile(override_toml_path)
        else
            Dict{String,Any}()
        end
        override_dict["d2c73de3-f751-5644-a686-071e5b155ba9"] = Dict("GR" => grdir)
        open(override_toml_path, "w") do io
            TOML.print(io, override_dict)
        end
    end

    """
        unoverride_depot()

    Remove the override for GR_jll in DEPOT_PATH[1]/artifats/Overrides.toml
    """
    function unoverride_depot()
        override_toml_path = get_override_toml_path()
        override_dict = if isfile(override_toml_path)
            TOML.parsefile(override_toml_path)
        else
            Dict{String,Any}()
        end
        delete!(override_dict, "d2c73de3-f751-5644-a686-071e5b155ba9")
        open(override_toml_path, "w") do io
            TOML.print(io, override_dict)
        end
    end

    """
        override_project([grdir])

    Override individual GR_jll artifacts in the (Local)Preferences.toml of the project.
    """
    function override_project(grdir = grdir[]; force = false)
        set_preferences!(
            Base.UUID("d2c73de3-f751-5644-a686-071e5b155ba9"), # GR_jll
            "libGR_path" => lib_path(grdir, "libGR"),
            "libGR3_path" => lib_path(grdir, "libGR3"),
            "libGRM_path" => lib_path(grdir, "libGRM"),
            "libGKS_path" => lib_path(grdir, "libGKS"),
            "gksqt_path" => gksqt_path(grdir);
            force
        )
    end

    """
        unoverride_project()

    Remove overrides for GR_jll artifacts in the (Local)Preferences.toml of the project.
    """
    function unoverride_project(; force = false)
        delete_preferences!(
            Base.UUID("d2c73de3-f751-5644-a686-071e5b155ba9"), # GR_jll
            "libGR_path",
            "libGR3_path",
            "libGRM_path",
            "libGKS_path",
            "gksqt_path";
            force
        )
    end
end
