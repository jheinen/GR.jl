using BinaryBuilder

name = "GR"
version = v"0.54.0"

# Collection of sources required to build gr
# qt5-runtime-Windows-x86_64.tar.gz was included to provide headers for Qt 5.12
sources = [
    "https://github.com/sciapp/gr/archive/v$(version).tar.gz" => "c4e57f3d7eaae1c77e7bc291966cab3b507f49801258158c9363a2157b6da104",
    "https://gr-framework.org/downloads/3rdparty/qt5-runtime-Windows-x86_64.tar.gz" => "8ba52b297fc093916ffb7fac8d9a70b404e77449ea31d1ab82bc442e3e8c01b5"
]

# Bash recipe for building across all platforms
script = raw"""
                    
# target variable interferes with 3rdparty builds
unset target
TARGET_ARCH=`echo ${LLVM_TARGET} | cut -d- -f1`
TARGET_OS=`echo ${LLVM_TARGET} | cut -d- -f2`
# Qt_jll only exists for some platforms
if [ -f "${WORKSPACE}/destdir/lib/libQt5Widgets.so" ]; then
    QT5_LIBRARY_DIR=${WORKSPACE}/destdir/lib/
fi
# a local Qt5 installation is required for moc and rcc executables
apk update
apk add qt5-qtbase-dev
cd ${WORKSPACE}/srcdir/gr-*/
# source archive is created without git version info, but CMake build requires GR version
echo '"""
*
"$version"
*
raw"""' > version.txt
# build all bundled thirdparty dependencies except for GLFW
make -C 3rdparty default extras \
    "EXTRAS=tiff ogg theora vpx openh264 ffmpeg zeromq pixman cairo" \
    OPENJP2_EXTRA_CMAKE_FLAGS=-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    OGG_EXTRA_CONFIGURE_FLAGS=--host=${LLVM_TARGET} \
    THEORA_CONFIGURE="autoreconf -fi -I m4 && ./configure" \
    THEORA_EXTRA_CONFIGURE_FLAGS="--host=${LLVM_TARGET} --build=x86_64-linux-gnu --disable-asm" \
    FFMPEG_EXTRA_CONFIGURE_FLAGS="--cross-prefix=${LLVM_TARGET}- --arch=${TARGET_ARCH} --target-os=${TARGET_OS}  --pkg-config=pkg-config" \
    PIXMAN_EXTRA_CONFIGURE_FLAGS="--host=${LLVM_TARGET}" \
    CAIRO_EXTRA_CONFIGURE_FLAGS="--host=${LLVM_TARGET}" \
    TIFF_EXTRA_CONFIGURE_FLAGS="--host=${LLVM_TARGET}" \
    ZEROMQ_EXTRA_CONFIGURE_FLAGS="--host=${LLVM_TARGET}"
mkdir build && cd build
cmake .. \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DGR_USE_BUNDLED_LIBRARIES=ON \
    -DGR_MANUAL_MOC_AND_RCC=ON \
    -DGR_FIND_QT5_BY_VARIABLES=ON \
    -DQt5_INCLUDE_DIR="${WORKSPACE}/srcdir/include" \
    -DQt5_LIBRARY_DIR="${QT5_LIBRARY_DIR}" \
    -DQT_MOC_EXECUTABLE="/usr/bin/moc-qt5" \
    -DQT_RCC_EXECUTABLE="/usr/bin/rcc-qt5"
make -j${nproc}
make install
# CMake does not install license
cp ../LICENSE.md ${prefix}/share/licenses/GR
"""
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Linux(:x86_64), Linux(:aarch64), Linux(:i686)]
# The products that we will ensure are always built
products = [
    LibraryProduct(["libGR", "gr"], :libGR),
    LibraryProduct(["libGR3", "gr3"], :libGR3),
    LibraryProduct(["libGRM", "grm"], :libGRM)
]
# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Qt_jll"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("Xorg_libXt_jll")
]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, allow_unsafe_flags=:true, verbose=:true, preferred_gcc_version=v"7")
