using Pkg, GR

LibGit2 = Pkg.GitTools.LibGit2
TOML = Pkg.TOML

Pkg.activate(; temp = true)
Pkg.add(["JSON", "Downloads"])

using Downloads, JSON

function available_channels()
    juliaup = "https://julialang-s3.julialang.org/juliaup"
    for i in 1:6
        buf = PipeBuffer()
        Downloads.download("$juliaup/DBVERSION", buf)
        dbversion = VersionNumber(readline(buf))
        dbversion.major == 1 || continue
        buf = PipeBuffer()
        Downloads.download(
            "$juliaup/versiondb/versiondb-$dbversion-x86_64-unknown-linux-gnu.json",
            buf,
        )
        json = JSON.parse(buf)
        haskey(json, "AvailableChannels") || continue
        return json["AvailableChannels"]
        sleep(10i)
    end
    return
end

"""
julia> is_latest("lts")
julia> is_latest("release")
"""
function is_latest(variant)
    channels = available_channels()
    ver = VersionNumber(split(channels[variant]["Version"], '+') |> first)
    dev = occursin("DEV", string(VERSION))  # or length(VERSION.prerelease) < 2
    return !dev &&
        VersionNumber(ver.major, ver.minor, 0, ("",)) ≤
        VERSION <
        VersionNumber(ver.major, ver.minor + 1)
end

if !is_latest("release")
    @warn "skipping test on julia $VERSION"
    exit(0)
end

Plots_jl = joinpath(mkpath(tempname()), "Plots.jl")
Plots_subdir = joinpath(Plots_jl, "Plots")
Plots_toml = joinpath(Plots_subdir, "Project.toml")

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

@show stable
for i ∈ 1:6
    try
        global repo = Pkg.GitTools.ensure_clone(stdout, Plots_jl, "https://github.com/JuliaPlots/Plots.jl")
        break
    catch err
        @warn err
        sleep(20i)
    end
end
obj = LibGit2.GitObject(repo, "Plots-v$stable")
hash = if isa(obj, LibGit2.GitTag)
    LibGit2.target(obj)
else
    LibGit2.GitHash(obj)
end |> string
@show hash
LibGit2.checkout!(repo, hash)
@assert isfile(Plots_toml) "checkout repo failed, bailing out"

# fake the supported GR version for testing (for `Pkg.develop`)
toml = TOML.parse(read(Plots_toml, String))
toml["compat"]["GR"] = GR.version()  
open(Plots_toml, "w") do io
  TOML.print(io, toml)
end
# Pkg.develop(path=Plots_subdir)
Pkg.activate(Plots_subdir)
# Pkg.resolve()
Pkg.instantiate(; workspace = true)
# Pkg.status(; workspace = true)
Pkg.status(["GR", "Plots"];  workspace = true)

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
