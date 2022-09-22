module GRPreferences
  using Preferences

  const os = if Sys.KERNEL == :NT
    :Windows
  else
    Sys.KERNEL
  end

  extension() = if os ≡ :Windows
    ".dll"
  elseif os ≡ :Darwin
    ".dylib"
  else
    ".so"
  end

  loadpath(grdir) = if os ≡ :Windows
    joinpath(grdir, "bin")
  elseif os ≡ :Darwin
    joinpath(grdir, "lib")
  else
    joinpath(grdir, "lib")
  end

  const binary = @load_preference("binary", "GR_jll")
  const libgr = @load_preference("libgr", "libGR" * extension())
  const libgr3 = @load_preference("libgr3", "libGR3" * extension())
  const libgrm = @load_preference("libgrm", "libGRM" * extension())

  function use_system_binary(grdir; export_prefs = false, force = false)
    grdir = loadpath(grdir)
    set_preferences!(GRPreferences,
        "binary" => "system",
        "grdir" => grdir,
        "libgr" => joinpath(grdir, "libGR" * extension()),
        "libgr3" => joinpath(grdir, "libGR3" * extension()),
        "libgrm" => joinpath(grdir, "libGRM" * extension()),
        export_prefs = export_prefs,
        force = force
    )
    return nothing
  end

  function use_jll_binary(; export_prefs = false, force = false)
    set_preferences!(GRPreferences,
        "binary" => "GR_jll",
        "grdir" => nothing,
        "libgr" => nothing,
        "libgr3" => nothing,
        "libgrm" => nothing,
        export_prefs = export_prefs,
        force = force
    )
    return nothing
  end

end