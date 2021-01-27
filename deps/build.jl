@static if !isdefined(Base, Symbol("@info"))
    macro info(msg)
        return :(info($(esc(msg))))
    end
end

function get_grdir()
    if "GRDIR" in keys(ENV)
        grdir = ENV["GRDIR"]
        have_dir = length(grdir) > 0
        if have_dir
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
    if have_dir
        @info("Found existing GR run-time in $grdir")
    end
    have_dir ? grdir : Nothing
end

function get_version()
    version = v"0.54.0"
    try
        @static if VERSION >= v"1.4.0-DEV.265"
            v = string(Pkg.dependencies()[Base.UUID("28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71")].version)
        else
            v = Pkg.API.installed()["GR"]
        end
    catch
    end
    if "GRDIR" in keys(ENV)
        if length(ENV["GRDIR"]) == 0
            version = "latest"
        end
    end
    version
end

function get_os_release(key)
    value = try
        String(read(pipeline(`cat /etc/os-release`, `grep ^$key=`, `cut -d= -f2`)))[1:end-1]
    catch
        ""
    end
    replace(value, "\"" => "")
end

function try_download(url, file)
    try
        download(url, file)
        true
    catch
        false
    end
end

const depsfile = joinpath(@__DIR__, "deps.jl")

if haskey(ENV, "JULIA_GR_PROVIDER")
    provider = ENV["JULIA_GR_PROVIDER"]
else
    provider = "GR"
end

if provider == "BinaryBuilder"
    open(depsfile, "w") do io
        println(io, """
            using GR_jll
        """)
    end
    exit(0)
elseif provider == "GR"
    rm(depsfile, force=true)
else
    @warn("Unrecognized JULIA_GR_PROVIDER \"$provider\".\n",
          "To fix this, set ENV[\"JULIA_GR_PROVIDER\"] to \"BinaryBuilder\" or \"GR\"\n",
          "and rerun Pkg.build(\"GR\").")
    exit(1)
end

if Sys.KERNEL == :NT
    os = :Windows
else
    os = Sys.KERNEL
end

grdir = get_grdir()

if grdir == Nothing
    arch = Sys.ARCH
    if os == :Linux && arch == :x86_64
        if isfile("/etc/redhat-release")
            rel = String(read(pipeline(`cat /etc/redhat-release`, `sed s/.\*release\ //`, `sed s/\ .\*//`)))[1:end-1]
            if rel > "7.0"
                os = "Redhat"
            end
        elseif isfile("/etc/os-release")
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
    elseif os == :Linux && arch in [:i386, :i686]
        arch = :i386
    elseif os == :Linux && arch == :arm
        id = get_os_release("ID")
        if id == "raspbian"
            os = "Debian"
        end
        arch = "armhf"
    elseif os == :Linux && arch == :aarch64
        id = get_os_release("ID")
        id_like = get_os_release("ID_LIKE")
        if id == "debian" || id_like == "debian"
            os = "Debian"
        end
    end
    version = get_version()
    tarball = "gr-$version-$os-$arch.tar.gz"
    rm("downloads", force=true, recursive=true)
    @info("Downloading pre-compiled GR $version $os binary")
    mkpath("downloads")
    file = "downloads/$tarball"
    if version != "latest"
        ok = try_download("https://github.com/sciapp/gr/releases/download/v$version/$tarball", file)
    else
        ok = false
    end
    if !ok
        if !try_download("https://gr-framework.org/downloads/$tarball", file)
            @info("Using insecure connection")
            if !try_download("http://gr-framework.org/downloads/$tarball", file)
                @info("Cannot download GR run-time")
            end
        end
    end
    if os == :Windows
        home = Sys.BINDIR
        if VERSION > v"1.3.0-"
            home =  joinpath(Sys.BINDIR, "..", "libexec")
        end
        success(`$home/7z x downloads/$tarball -y`)
        rm("downloads/$tarball")
        tarball = tarball[1:end-3]
        success(`$home/7z x $tarball -y -ttar`)
        rm(tarball)
    else
        run(`tar xzf downloads/$tarball`)
        rm("downloads/$tarball")
    end
    if os == :Darwin
        app = joinpath("gr", "Applications", "GKSTerm.app")
        run(`/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $app`)
        try
            @static if VERSION >= v"1.4.0-DEV.265"
                have_qml = haskey(Pkg.dependencies(),Base.UUID("2db162a6-7e43-52c3-8d84-290c1c42d82a"))
            else
                have_qml = haskey(Pkg.API.installed(), "QML")
            end
            if have_qml
                @eval import QML
                qt = QML.qt_prefix_path()
                path = joinpath(qt, "Frameworks")
                if isdir(path)
                    qt5plugin = joinpath(pwd(), "gr", "lib", "qt5plugin.so")
                    run(`install_name_tool -add_rpath $path $qt5plugin`)
                    @info("Using Qt " * splitdir(qt)[end] * " at " * qt)
                end
            end
        catch
        end
    end
end

if os == :Linux || os == :FreeBSD
    global grdir
    try
        if grdir == Nothing
            grdir = joinpath(pwd(), "gr")
        end
        gksqt = joinpath(grdir, "bin", "gksqt")
        res = read(`ldd $gksqt`, String)
        if occursin("not found", res)
            @warn("Missing dependencies for GKS QtTerm. Did you install the Qt5 run-time?")
            @warn("Please refer to https://gr-framework.org/julia.html for further information.")
        end
    catch
    end
end
