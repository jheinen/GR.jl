module GRPreferences
    using Preferences
    using Artifacts
    using TOML
    import Scratch
    import Requires
    try
        import GRCore_jll
    catch err
        @debug """
        import GRCore_jll failed.
        Consider using `GR.GRPreferences.use_jll_binary()` or
        `GR.GRPreferences.use_upstream_binary()` to repair.
        Importing GR a second time will allow use of these functions.
        """
    end
    include("downloader.jl")

    const grcore_jll_uuid = Base.UUID("f74edf77-fc28-5533-a68a-cacf3c4a2f46")

    const grdir   = Ref{Union{Nothing,String}}()
    const gksqt   = Ref{Union{Nothing,String}}()
    const grplot  = Ref{Union{Nothing,String}}()
    const libGR   = Ref{Union{Nothing,String}}()
    const libGR3  = Ref{Union{Nothing,String}}()
    const libGRM  = Ref{Union{Nothing,String}}()
    const libGKS  = Ref{Union{Nothing,String}}()
    const libpath = Ref{Union{Nothing,String}}()

    const pkg_version = VersionNumber(TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["version"])
    const GR_jll_scratch = Ref{String}()

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

    # Copy all files from a tree. Adapted from the JLLPrefixes package.
    function copy_tree(src::AbstractString, dest::AbstractString)
        for (root, dirs, files) in walkdir(src)
            # Create all directories
            for d in dirs
                d_path = joinpath(root, d)
                dest_dir = joinpath(dest, relpath(root, src), d)
                if !ispath(dest_dir)
                    mkpath(dest_dir)
                end
            end
    
            # Copy all files
            for f in files
                src_file = joinpath(root, f)
                dest_file = joinpath(dest, relpath(root, src), f)
                if isfile(dest_file)
                    # Ugh, destination file already exists.  If source and destination files
                    # have the same size and SHA256 hash, just move on, otherwise issue a
                    # warning.
                    if filesize(src_file) == filesize(dest_file)
                        src_file_hash = open(io -> bytes2hex(sha256(io)), src_file, "r")
                        dest_file_hash = open(io -> bytes2hex(sha256(io)), dest_file, "r")
                        if src_file_hash == dest_file_hash
                            continue
                        end
                    end
    
                    # Find source artifact that this pre-existent destination file belongs to
                    @warn("File $(f) from $(dirname(src_file)) already exists in $(dest)")
                else
                    # If it's already a symlink, copy over the exact symlink target
                    cp(src_file, dest_file)
                end
            end
        end
    end

    function __init__()
        gr_jll_artifact_dir = GRCore_jll.artifact_dir
        default_binary = haskey(ENV, "GRDIR") &&
            ENV["GRDIR"] != gr_jll_artifact_dir ? "system" : "GR_jll"
        binary = @load_preference("binary", default_binary)
        if binary == "GR_jll"
            scratch_name = "gr_prefix-$(pkg_version.major).$(pkg_version.minor)"
            grdir[] = Scratch.@get_scratch!(scratch_name)
            if !isdir(joinpath(grdir[], "lib"))
                copy_tree(GRCore_jll.artifact_dir, grdir[])
            end

            gksqt[]   = nothing
            grplot[]  = nothing
            libGR[]   = GRCore_jll.libGR
            libGR3[]  = GRCore_jll.libGR3
            libGRM[]  = GRCore_jll.libGRM
            libGKS[]  = GRCore_jll.libGKS
            
            # Because GRCore_jll does not dlopen as of 0.69.1+1, we need to append
            # the LIBPATH_list similar to JLLWrappers.@init_library_product
            grcore_libdir = dirname(GRCore_jll.libGR)
            push!(GRCore_jll.LIBPATH_list, grcore_libdir)
            push!(GRCore_jll.LIBPATH_list, joinpath(grdir[], basename(grcore_libdir))) # add scratchdir/bin or scratchdir/lib
            # Recompute LIBPATH similar to JLLWrappers.@generate_init_footer
            unique!(GRCore_jll.LIBPATH_list)
            pathsep = GRCore_jll.JLLWrappers.pathsep
            GRCore_jll.LIBPATH[] = join(vcat(GRCore_jll.LIBPATH_list, Base.invokelatest(GRCore_jll.JLLWrappers.get_julia_libpaths))::Vector{String}, pathsep)

            libpath[] = GRCore_jll.LIBPATH[]
            ENV["GRDIR"] = grdir[]

            @static if !isdefined(Base, :get_extension)
                Requires.@require GRQt5_jll = "be234c1c-6cf4-5063-8676-3229d64ce17a" begin include("../ext/GRQt5Ext.jl") end
            end
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
    * :depot, Override GRCore_jll using the depot Overrides.toml
    * :project, Override GRCore_jll using the project Preferences.toml
    * (:depot, :project), Overide GRCore_jll in both the depot and the project
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

    Use GRCore_jll in the its standard configuration from BinaryBuilder.org.

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

    Override GRCore_jll in the DEPOT_PATH[1]/artifacts/Overrides.toml with `grdir`.
    """
    function override_depot(grdir = grdir[])
        overrides_toml_path = get_overrides_toml_path()
        override_dict = if isfile(overrides_toml_path)
            TOML.parsefile(overrides_toml_path)
        else
            Dict{String,Any}()
        end
        override_dict[string(grcore_jll_uuid)] = Dict("GR" => grdir)
        open(overrides_toml_path, "w") do io
            TOML.print(io, override_dict)
        end
    end

    """
        unoverride_depot()

    Remove the override for GRCore_jll in DEPOT_PATH[1]/artifats/Overrides.toml
    """
    function unoverride_depot()
        overrides_toml_path = get_overrides_toml_path()
        override_dict = if isfile(overrides_toml_path)
            TOML.parsefile(overrides_toml_path)
        else
            Dict{String,Any}()
        end
        delete!(override_dict, string(grcore_jll_uuid))
        open(overrides_toml_path, "w") do io
            TOML.print(io, override_dict)
        end
    end

    """
        override_project([grdir])

    Override individual GRCore_jll artifacts in the (Local)Preferences.toml of the project.
    """
    function override_project(grdir = grdir[]; force = false)
        set_preferences!(
            grcore_jll_uuid,
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

    Remove overrides for GRCore_jll artifacts in the (Local)Preferences.toml of the project.
    """
    function unoverride_project(; force = false)
        delete_preferences!(
            grcore_jll_uuid,
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

    Output diagnostics about preferences and overrides for GR and GRCore_jll.
    """
    function diagnostics()
        # GR Preferences
        binary = @load_preference("binary")
        grdir = @load_preference("grdir")

        # GRCore_jll Preferences
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
        @info "GRCore_jll Preferences" libGR_path libGR3_path libGRM_path libGKS_path gksqt_path grplot_path
        @info "GRCore_jll Overrides.toml" overrides_toml_path isfile(overrides_toml_path) get(gr_jll_override_dict, "GR", nothing)

        if(isdefined(@__MODULE__, :GRCore_jll))
            @info "GRCore_jll" GRCore_jll.libGR_path GRCore_jll.libGR3_path GRCore_jll.libGRM_path GRCore_jll.libGKS_path
        else
            @info "GRCore_jll is not loaded"
        end

        return (;
                binary, grdir,
                libGR_path, libGR3_path, libGRM_path, libGKS_path, gksqt_path, grplot_path,
                overrides_toml_path, gr_jll_override_dict
        )
    end
end
