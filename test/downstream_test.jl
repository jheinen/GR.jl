using Pkg, GR

LibGit2 = Pkg.GitTools.LibGit2
TOML = Pkg.TOML

Plots_jl = joinpath(mkpath(tempname()), "Plots.jl")
Plots_toml = joinpath(Plots_jl, "Project.toml")

# clone and checkout the latest stable version of Plots
stable = try
    rg = first(Pkg.Registry.reachable_registries())
    Plots_UUID = first(Pkg.Registry.uuids_from_name(rg, "Plots"))
    Plots_PkgEntry = rg.pkgs[Plots_UUID]
    Plots_version_info = Pkg.Registry.registry_info(Plots_PkgEntry).version_info
    maximum(keys(Plots_version_info))
catch
    depot = joinpath(first(DEPOT_PATH), "registries", "General", "P", "Plots", "Versions.toml")
    maximum(VersionNumber.(keys(TOML.parse(read(depot, String)))))
end

for i ∈ 1:6
    try
        global repo = Pkg.GitTools.ensure_clone(stdout, Plots_jl, "https://github.com/JuliaPlots/Plots.jl")
        break
    catch err
        @warn err
        sleep(20i)
    end
end
@assert isfile(Plots_toml) "spurious network error: clone failed, bailing out"
tag = LibGit2.GitObject(repo, "v$stable")
hash = string(LibGit2.target(tag))
LibGit2.checkout!(repo, hash)

# fake the supported GR version for testing (for `Pkg.develop`)
toml = TOML.parse(read(Plots_toml, String))
toml["compat"]["GR"] = GR.version()  
open(Plots_toml, "w") do io
  TOML.print(io, toml)
end
Pkg.develop(path=Plots_jl)
Pkg.status(["GR", "Plots"])

# test basic plots creation and bitmap or vector exports
using Plots, Test

prefix = tempname()
@time for i ∈ 1:length(Plots._examples)
  i ∈ Plots._backend_skips[:gr] && continue  # skip unsupported examples
  Plots._examples[i].imports ≡ nothing || continue  # skip examples requiring optional test deps
  pl = Plots.test_examples(:gr, i; disp = false)
  for ext in (".png", ".pdf")  # TODO: maybe more ?
    fn = string(prefix, i, ext)
    Plots.savefig(pl, fn)
    @test filesize(fn) > 1_000
  end
end
