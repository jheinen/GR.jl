"""
    GR.GRPreferences.Downloader is a Module that contains the GR download script.

GR.GRPreferences.Downloader.download() can be invoked manually.
"""
module Downloader

using Pkg
using UUIDs
using Tar
using Downloads
using p7zip_jll

const version = v"0.73.3"
const GR_UUID = UUID("28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71")


"""
    get_grdir()

Try to locate an existing GR install. The search will look
in the following places:
1. ENV["GRDIR"]
2. ~/gr
3. /opt/gr
4. /usr/local/gr
5. /usr/gr

It will confirm the install by checking for the existence of a fonts
subdirectory.

The function will return a `String` representing one of the paths above
or `nothing` if a GR install is not located in any of those locations.
"""
function get_grdir()
    if "GRDIR" in keys(ENV)
        grdir = ENV["GRDIR"]
        if (have_dir = !isempty(grdir))
            have_dir = isdir(joinpath(grdir, "fonts"))
        end
    else
        have_dir = false
        for d in (homedir(), "/opt", "/usr/local", "/usr")
            grdir = joinpath(d, "gr")
            if isdir(joinpath(grdir, "fonts"))
                have_dir = true
                break
            end
        end
    end
    have_dir && @info "Found existing GR run-time in $grdir"
    return have_dir ? grdir : nothing
end

"""
    get_version()

Get the version of GR.jl package.

If ENV["GRDIR"] exists and non-empty, this will return "latest"
"""
function get_version()
    _version = version
    if "GRDIR" in keys(ENV)
        if isempty(ENV["GRDIR"])
            _version = "latest"
        end
    end
    return _version
end

"""
    get_os_release(key)

Grep for key in /etc/os-release
"""
function get_os_release(key)
    value = ""
    try
        #String(read(pipeline(`cat /etc/os-release`, `grep ^$key=`, `cut -d= -f2`)))[1:end-1]
        for line in readlines("/etc/os-release")
            if startswith(line, "$key=")
                value = split(line, "=")[2]
            end
        end
    catch
    end
    return replace(value, "\"" => "")
end

"""
    get_os_and_arch()

Figure out which specific operating system this, including the specific Linux distribution.
"""
function get_os_and_arch()
    os = Sys.iswindows() ? "Windows" : string(Sys.KERNEL)

    arch = Sys.ARCH

    if Sys.islinux() && Sys.ARCH == :x86_64
        if isfile("/etc/redhat-release")
            # example = "Red Hat Enterprise Linux Server release 6.5 (Santiago)"
            #=
            rel = String(
                read(
                    pipeline(
                        `cat /etc/redhat-release`,
                        `sed s/.\*release\ //`,
                        `sed s/\ .\*//`,
                    ),
                ),
            )[1:end-1]
            =#
            rel = read("/etc/redhat-release", String)
            rel = replace(rel, r".*release " => "", r" .*" => "")
            rel = strip(rel)
            if rel > "7.0"
                os = "Redhat"
            end
        elseif isfile("/etc/os-release")
            #=
            example = """
            PRETTY_NAME="Ubuntu 22.04.1 LTS"
            NAME="Ubuntu"
            VERSION_ID="22.04"
            VERSION="22.04.1 LTS (Jammy Jellyfish)"
            VERSION_CODENAME=jammy
            ID=ubuntu
            ID_LIKE=debian
            HOME_URL="https://www.ubuntu.com/"
            SUPPORT_URL="https://help.ubuntu.com/"
            BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
            PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
            UBUNTU_CODENAME=jammy
            """
            =#
            id = get_os_release("ID")
            id_like = get_os_release("ID_LIKE")
            if id == "ubuntu" || id == "pop" || id_like == "ubuntu"
                os = "Ubuntu"
            elseif id == "debian" || id_like == "debian"
                os = "Debian"
            elseif id == "arch" || id_like == "arch" || id_like == "archlinux"
                os = "ArchLinux"
            elseif id == "opensuse-tumbleweed"
                os = "CentOS"
            end
        end
    elseif Sys.islinux() && Sys.ARCH in [:i386, :i686]
        arch = :i386
    elseif Sys.islinux() && Sys.ARCH == :arm
        id = get_os_release("ID")
        if id == "raspbian"
            os = "Debian"
        end
        arch = "armhf"
    elseif Sys.islinux() && Sys.ARCH == :aarch64
        id = get_os_release("ID")
        id_like = get_os_release("ID_LIKE")
        if id == "debian" ||
           id_like == "debian" ||
           id == "archarm" ||
           id_like == "arch"
            os = "Debian"
        end
    end

    return os, arch
end

"""
    try_download(url, file)

Try to download url to file. Return `true` if successful, or `false` otherwise.
"""
function try_download(url, file)
    try
        Downloads.download(url, file)
        true
    catch err
        rethrow()
        false
    end
end

"""
    check_dependencies(grdir::String)

Check dependencies using ldd on Linux and FreeBSD
"""
function check_dependencies(grdir::String)
    try
        gksqt = joinpath(grdir, "bin", "gksqt")
        res = read(`ldd $gksqt`, String)
        if occursin("not found", res)
            @warn """
            Missing dependencies for GKS QtTerm. Did you install the Qt5 run-time ?
            Please refer to https://gr-framework.org/julia.html for further information.
            """
        end
    catch
        # Fail silently
    end
end

"""
    apple_install(grdir::String)

Register launch services and install rpath for qt5plugin.so
"""
function apple_install(grdir::String)
    app = joinpath(grdir, "Applications", "GKSTerm.app")
    run(
        `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $app`,
    )
    try
        have_qml = @static if VERSION >= v"1.4.0-DEV.265"
            haskey(
                Pkg.dependencies(),
                UUID("2db162a6-7e43-52c3-8d84-290c1c42d82a"),
            )
        else
            haskey(Pkg.API.installed(), "QML")
        end
        # Set rpath of gr/lib/qt5plugin.so to that of QML
        if have_qml
            @eval import QML
            qt = QML.qt_prefix_path()
            path = joinpath(qt, "Frameworks")
            if isdir(path)
                qt5plugin = joinpath(grdir, "lib", "qt5plugin.so")
                run(`install_name_tool -add_rpath $path $qt5plugin`)
                @info("Using Qt " * splitdir(qt)[end] * " at " * qt)
            end
        end
    catch
        # Fail silently
    end
end


"""
    get_default_install_dir()

Return the default install directory where we have write permissions.
Currently, this is the deps directory of the GR package:
`joinpath(pathof(GR), "..", "deps")`
"""
get_default_install_dir() =
    abspath(joinpath(@__DIR__, "..", "deps"))

"""
    download_tarball(version, os, arch, downloads_dir = mktempdir())

Download tarball to downloads_dir.
"""
function download_tarball(version, os, arch, downloads_dir = mktempdir())
    tarball = "gr-$version-$os-$arch.tar.gz"
    file = joinpath(downloads_dir, tarball)

    @info("Downloading pre-compiled GR $version $os binary", file)
    # Download versioned tarballs from Github
    ok = if version != "latest"
        try_download(
            "https://github.com/sciapp/gr/releases/download/v$version/$tarball",
            file,
        )
    else
        false
    end

    # Download latest tarball from gr-framework.org
    if !ok && !try_download("https://gr-framework.org/downloads/$tarball", file)
        @warn "Using insecure connection"
        try_download("http://gr-framework.org/downloads/$tarball", file) ||
            error("Cannot download GR run-time")
    end

    return file
end

"""
    download(install_dir)

Download tarball from https://github.com/sciapp/gr/releases and extract the
tarball into install_dir. 
"""
function download(install_dir = get_default_install_dir(); force = false)

    # If the install_dir path ends in gr, then install in the parent dir
    # Use a trailing slash if you really want the install in gr/gr
    basename(install_dir) == "gr" && (install_dir = dirname(install_dir))

    # Configure directories
    destination_dir = joinpath(install_dir, "gr")

    # Ensure the install directory exists
    mkpath(install_dir)

    grdir = if force
        # Download regardless if an existing installation exists
        nothing
    else
        # Check for an existing installation
        get_grdir()
    end

    # We did not find an existing installation
    if isnothing(grdir)

        # Identify the following so we can download a proper tarball
        # 1. version (version of the GR package)
        version = get_version()
        # 2. os (operating system)
        # 3. arch (processor architecture)
        os, arch = get_os_and_arch()

        # Download the tarball
        mktempdir() do downloads_dir
            file = download_tarball(version, os, arch, downloads_dir)

            # Extract the tarball
            if isdir(destination_dir) || force
                rm(destination_dir; force=force, recursive=true)
            end
            mktempdir() do extract_dir
                @static if VERSION >= v"1.7"
                    kwargs = (; set_permissions = !Sys.iswindows())
                else
                    kwargs = (;)
                end
                Tar.extract(`$(p7zip_jll.p7zip()) x $file -so`, extract_dir; kwargs...)
                mv(joinpath(extract_dir, "gr"), destination_dir)
            end
            rm(file)
        end

        # Address Mac specific framework and rpath issues
        Sys.isapple() && apple_install(destination_dir)

        grdir = destination_dir
    end # if isnothing(grdir)

    # Check dependencies when using Linux or FreeBSD
    (Sys.islinux() || Sys.isfreebsd()) && check_dependencies(grdir)

    @info "grdir" grdir
    return grdir

end # download()

end # module Builder
