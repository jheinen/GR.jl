# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GR"
version = v"0.56.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sciapp/gr.git", "c5fbc6613de1437a3dd598680de02af8dbe1098f"),
    FileSource("https://github.com/sciapp/gr/releases/download/v$version/gr-$version.js",
               "1e372730b864b105a4091cb2fd0814156aea8992ef0db308b9695956a292acc8", "gr.js")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gr

if test -f "$prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake"; then
    sed -i 's/_qt5gui_find_extra_libs.*AGL.framework.*//' $prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake
fi

update_configure_scripts

make -C 3rdparty/qhull -j${nproc}

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DGR_USE_BUNDLED_LIBRARIES=ON -DTIFF_LIBRARY=${libdir}/libtiff.${dlext} -DCMAKE_BUILD_TYPE=Release ..

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
cp ../../gr.js ${libdir}/

install_license $WORKSPACE/srcdir/gr/LICENSE.md

if [[ $target == *"apple-darwin"* ]]; then
    cd $prefix/bin
    ln -s ../Applications/gksqt.app/Contents/MacOS/gksqt ./
    ln -s ../Applications/GKSTerm.app/Contents/MacOS/GKSTerm ./
fi
"""

#platforms = supported_platforms()

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
#    Linux(:i686, libc=:musl),
#    Linux(:x86_64, libc=:musl),
#    Linux(:aarch64, libc=:musl),
#    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libGR", :libGR),
    LibraryProduct("libGR3", :libGR3),
    LibraryProduct("libGRM", :libGRM),
    LibraryProduct("libGKS", :libGKS),
    ExecutableProduct("gksqt", :gksqt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"),
    Dependency("Cairo_jll"),
    Dependency("FFMPEG_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("GLFW_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Pixman_jll"),
    Dependency("Libtiff_jll"),
    Dependency("Qt_jll"),
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC version 7 because of ffmpeg, but building against Qt requires v8 on Windows.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"8")
