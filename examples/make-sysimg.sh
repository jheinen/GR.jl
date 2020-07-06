#!/bin/sh

julia="julia"
if [ "${JULIA}" != "" ]
then
    julia=${JULIA}
fi

${julia} -e 'using PackageCompiler; create_sysimage(:GR; precompile_execution_file=joinpath(pwd(), "snoop.jl"), sysimage_path=joinpath(pwd(), "sys"))' >/dev/null

echo To use the new system image, please start Julia with the -J option:
echo ${julia} -J sys
