#!/bin/sh

julia -e 'using PackageCompiler; compile_incremental("GR", joinpath(pwd(), "snoop.jl"))' >/dev/null

img=`julia -e 'import PackageCompiler; println(normpath(joinpath(dirname(pathof(PackageCompiler)), "..", "sysimg", "sys")))'`

echo To use the new system image, please start Julia with the -J option:
echo julia -J ${img}
