module GRPreferences
    using Preferences
    using Artifacts
    using TOML
    try
        import GR_jll
    catch err
        @debug """
        import GR_jll failed.
        Consider using `GR.GRPreferences.use_jll_binary()` or
        `GR.GRPreferences.use_upstream_binary()` to repair.
        Importing GR a second time will allow use of these functions.
        """
    end
    include("downloader.jl")

    const grdir   = Ref{Union{Nothing,String}}()
    const gksqt   = Ref{Union{Nothing,String}}()
    const grplot  = Ref{Union{Nothing,String}}()
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

    grplot_path(grdir) =
        if Sys.iswindows()
            joinpath(grdir, "bin", "grplot.exe")
        elseif Sys.isapple()
            joinpath(grdir, "Applications", "grplot.app", "Contents", "MacOS", "grplot")
        else
            joinpath(grdir, "bin", "grplot")
        end

    # Default grdir to deps/gr if nothing
    grplot_path(grdir::Nothing) =
        grplot_path(joinpath(@__DIR__, "..", "deps", "gr"))

    function __init__()
        gr_jll_artifact_dir = GR_jll.artifact_dir
        default_binary = haskey(ENV, "GRDIR") &&
            ENV["GRDIR"] != gr_jll_artifact_dir ? "system" : "GR_jll"
        binary = @load_preference("binary", default_binary)
        if binary == "GR_jll"
            grdir[]   = gr_jll_artifact_dir
            gksqt[]   = GR_jll.gksqt_path
            grplot[]  = GR_jll.grplot_path
            libGR[]   = GR_jll.libGR
            libGR3[]  = GR_jll.libGR3
            libGRM[]  = GR_jll.libGRM
            libGKS[]  = GR_jll.libGKS

            # Because GR_jll does not dlopen as of 0.69.1+1, we need to append
            # the LIBPATH_list similar to JLLWrappers.@init_library_product
            push!(GR_jll.LIBPATH_list, dirname(GR_jll.libGR))
            # Recompute LIBPATH similar to JLLWrappers.@generate_init_footer
            unique!(GR_jll.LIBPATH_list)
            pathsep = GR_jll.JLLWrappers.pathsep
            GR_jll.LIBPATH[] = join(vcat(GR_jll.LIBPATH_list, Base.invokelatest(GR_jll.JLLWrappers.get_julia_libpaths))::Vector{String}, pathsep)

            libpath[] = GR_jll.LIBPATH[]
            ENV["GRDIR"] = grdir[]
        elseif binary == "system"
            grdir[]   = haskey(ENV, "GRDIR") ? ENV["GRDIR"] : @load_preference("grdir")
            gksqt[]   = gksqt_path(grdir[])
            grplot[]  = grplot_path(grdir[])
            libGR[]   = lib_path(grdir[], "libGR")
            libGR3[]  = lib_path(grdir[], "libGR3")
            libGRM[]  = lib_path(grdir[], "libGRM")
            libGKS[]  = lib_path(grdir[], "libGKS")
            libpath[] = lib_path(grdir[], "")
            ENV["GRDIR"] = grdir[]
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
        :depot in override && override_depot(grdir)
        :project in override && override_project(grdir; force)
        __init__()
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
        __init__()
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
        grdir = Downloader.download(args...; force)
        use_system_binary(grdir; export_prefs, force, override)
    end

    """
        get_overrides_toml_path()

    Get the path the depot's Overrides.toml
    """
    function get_overrides_toml_path()
        overrides_toml_path = joinpath(Artifacts.artifacts_dirs()[1], "Overrides.toml")
    end

    """
        override_depot([grdir])

    Override GR_jll in the DEPOT_PATH[1]/artifacts/Overrides.toml with `grdir`.
    """
    function override_depot(grdir = grdir[])
        overrides_toml_path = get_overrides_toml_path()
        override_dict = if isfile(overrides_toml_path)
            TOML.parsefile(overrides_toml_path)
        else
            Dict{String,Any}()
        end
        override_dict["d2c73de3-f751-5644-a686-071e5b155ba9"] = Dict("GR" => grdir)
        open(overrides_toml_path, "w") do io
            TOML.print(io, override_dict)
        end
    end

    """
        unoverride_depot()

    Remove the override for GR_jll in DEPOT_PATH[1]/artifats/Overrides.toml
    """
    function unoverride_depot()
        overrides_toml_path = get_overrides_toml_path()
        override_dict = if isfile(overrides_toml_path)
            TOML.parsefile(overrides_toml_path)
        else
            Dict{String,Any}()
        end
        delete!(override_dict, "d2c73de3-f751-5644-a686-071e5b155ba9")
        open(overrides_toml_path, "w") do io
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
            "gksqt_path" => gksqt_path(grdir),
            "grplot_path" => grplot_path(grdir);
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
            "gksqt_path",
            "grplot_path";
            force
        )
    end

    """
        diagnostics()

    Output diagnostics about preferences and overrides for GR and GR_jll.
    """
    function diagnostics()
        # GR Preferences
        binary = @load_preference("binary")
        grdir = @load_preference("grdir")

        # GR_jll Preferences
        GR_jll_uuid = Base.UUID("d2c73de3-f751-5644-a686-071e5b155ba9")
        libGR_path = load_preference(GR_jll_uuid, "libGR_path")
        libGR3_path = load_preference(GR_jll_uuid, "libGR3_path")
        libGRM_path = load_preference(GR_jll_uuid, "libGRM_path")
        libGKS_path = load_preference(GR_jll_uuid, "libGKS_path")
        gksqt_path = load_preference(GR_jll_uuid, "gksqt_path")
        grplot_path = load_preference(GR_jll_uuid, "grplot_path")

        # Override.toml in DEPOT_PATH
        overrides_toml_path = get_overrides_toml_path()
        override_dict = if isfile(overrides_toml_path)
            TOML.parsefile(overrides_toml_path)
        else
            Dict{String,Any}()
        end
        gr_jll_override_dict = get(override_dict, string(GR_jll_uuid), Dict{String,Any}())
        resolved_grdir = haskey(ENV, "GRDIR") ? ENV["GRDIR"] : grdir

        # Output
        @info "GRDIR Environment Variable" get(ENV, "GRDIR", missing)
        @info "GR Preferences" binary grdir
        isnothing(resolved_grdir) ||
            @info "resolved_grdir" resolved_grdir isdir(resolved_grdir) isdir.(joinpath.((resolved_grdir,), ("bin", "lib", "include", "fonts")))
        @info "GR_jll Preferences" libGR_path libGR3_path libGRM_path libGKS_path gksqt_path grplot_path
        @info "GR_jll Overrides.toml" overrides_toml_path isfile(overrides_toml_path) get(gr_jll_override_dict, "GR", nothing)

        if(isdefined(@__MODULE__, :GR_jll))
            @info "GR_jll" GR_jll.libGR_path GR_jll.libGR3_path GR_jll.libGRM_path GR_jll.libGKS_path GR_jll.gksqt_path GR_jll.grplot_path
        else
            @info "GR_jll is not loaded"
        end

        return (;
                binary, grdir,
                libGR_path, libGR3_path, libGRM_path, libGKS_path, gksqt_path, grplot_path,
                overrides_toml_path, gr_jll_override_dict
        )
    end
end
