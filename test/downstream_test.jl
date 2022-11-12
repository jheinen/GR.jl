using Pkg, GR

LibGit2 = Pkg.GitTools.LibGit2
TOML = Pkg.TOML

Plots_jl = joinpath(mkpath(tempname()), "Plots.jl")

# clone and checkout the latest stable version of Plots
depot = joinpath(first(DEPOT_PATH), "registries", "General", "P", "Plots", "Versions.toml")
stable = maximum(VersionNumber.(keys(TOML.parse(read(depot, String)))))
repo = Pkg.GitTools.ensure_clone(stdout, Plots_jl, "https://github.com/JuliaPlots/Plots.jl")
tag = LibGit2.GitObject(repo, "v$stable")
hash = string(LibGit2.target(tag))
LibGit2.checkout!(repo, hash)

# fake the suported GR version for testing
Plots_toml = joinpath(Plots_jl, "Project.toml")
toml = TOML.parse(read(Plots_toml, String))
toml["compat"]["GR"] = GR.version()  
open(Plots_toml, "w") do io
  TOML.print(io, toml)
end
Pkg.develop(path=Plots_jl)
Pkg.status(["Plots", "GR"])

# test basic plots creation and bitmap or vector exports
using Plots, Test

prefix = tempname()
@time for i ∈ 1:length(Plots._examples)
  i ∈ Plots._backend_skips[:gr] && continue  # skip unsupported examples
  Plots._examples[i].imports === nothing || continue  # skip examples requiring optional test deps
  pl = Plots.test_examples(:gr, i; disp = false)
  for ext in (".png", ".pdf")
    fn = string(prefix, i, ext)
    Plots.savefig(pl, fn)
    @test filesize(fn) > 1_000
  end
end
