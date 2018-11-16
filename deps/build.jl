@static if !isdefined(Base, Symbol("@info"))
    macro info(msg)
        return :(info($(esc(msg))))
    end
end

@static if VERSION >= v"0.7.0-DEV.3656"
    using Pkg.API: installed
end

function check_grdir()
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
        @info "Found exisitng GR run-time in $grdir"
    end
    have_dir
end

function get_version()
    version = v"0.36.0"
    try
@static if VERSION >= v"0.7.0-DEV.3656"
        v = installed()["GR"]
else
        v = Pkg.installed("GR")
end
        if string(v)[end:end] == "+"
            version = "latest"
        end
    catch
    end
    version
end

function get_os_release(key)
    value = try
        String(read(pipeline(`cat /etc/os-release`, `grep ^$key=`, `cut -d= -f2`)))[1:end-1]
    catch
        ""
    end
    if VERSION < v"0.7-"
        replace(value, "\"", "")
    else
        replace(value, "\"" => "")
    end
end

if !check_grdir()
  if Sys.KERNEL == :NT
    os = :Windows
  else
    os = Sys.KERNEL
  end
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
      if id == "ubuntu" || id_like == "ubuntu"
        os = "Ubuntu"
      elseif id == "debian" || id_like == "debian"
        os = "Debian"
      end
    end
  elseif os == :Linux && arch in [:i386, :i686]
    arch = :i386
  end
  version = get_version()
  tarball = "gr-$version-$os-$arch.tar.gz"
  if !isfile("downloads/$tarball")
    @info("Downloading pre-compiled GR $version $os binary")
    url = "gr-framework.org/downloads/$tarball"
    file = "downloads/$tarball"
    mkpath("downloads")
    try
      download("https://$url", file)
    catch
      @info("Using insecure connection")
      try
        download("http://$url", file)
      catch
        @info("Cannot download GR run-time")
      end
    end
    if os == :Windows
      home = (VERSION < v"0.7-") ? JULIA_HOME : Sys.BINDIR
      success(`$home/7z x downloads/$tarball -y`)
      rm("downloads/$tarball")
      tarball = tarball[1:end-3]
      success(`$home/7z x $tarball -y -ttar`)
      rm(tarball)
    else
      run(`tar xzf downloads/$tarball`)
      rm("downloads/$tarball")
    end
  end
  if os == :Darwin
    app = joinpath("gr", "Applications", "GKSTerm.app")
    run(`/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $app`)
    try
@static if VERSION >= v"0.7.0-DEV.3656"
      have_qml = haskey(installed(), "QML")
else
      have_qml = Pkg.installed("QML") != nothing
end
      if have_qml
        @eval import QML
        qt = QML.qt_prefix_path()
        path = joinpath(qt, "Frameworks")
        if isdir(path)
          qt5plugin = joinpath(pwd(), "gr", "lib", "qt5plugin.so")
          run(`install_name_tool -add_rpath $path $qt5plugin`)
          println("Using Qt ", splitdir(qt)[end], " at ", qt)
        end
      end
    catch
    end
  end
end
