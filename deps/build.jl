@static if !isdefined(Base, Symbol("@info"))
    macro info(msg)
        return :(info($(esc(msg))))
    end
end

using Pkg

@info "Building GR"

function check_grdir()
    if "GRDIR" in keys(ENV)
        GRDIR = ENV["GRDIR"]
        have_dir = length(GRDIR) > 0
        if have_dir
          @info "Found GRDIR in environment [$GRDIR]"
        else
          @info "Found GRDIR in environment, as empty string, will use a local one."
        end
        return have_dir
    end
    GRDIR = joinpath(homedir(), "gr")
    if isdir(GRDIR, "fonts")
        return true
    end

    for d in (homedir(), "/opt", "/usr/local", "/usr")
        GRDIR = joinpath(d, "gr")
        if isdir(GRDIR, "fonts")
          @info "Found GRDIR in homedir [$GRDIR]"
          return true
        end
    end

    @info "No existing gr found.  Will download one."
    
    return false
end

function get_version()
    version = v"0.34.1"
    try
        v = Pkg.installed("GR")
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
  # Download GR
  if Sys.KERNEL == :NT
    os = :Windows
  else
    os = Sys.KERNEL
  end
  const arch = Sys.ARCH
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
  end
  version = get_version()
  tarball = "gr-$version-$os-$arch.tar.gz"
  file = "downloads/$tarball"
  if !isfile(file)
    @info("Downloading pre-compiled GR $version $os binary to $file")
    url = "gr-framework.org/downloads/$tarball"
    mkpath("downloads")
    function get(http_url)
       try
        tmp = "$file.tmp"
        @info "Downloading $http_url"
        download(http_url, tmp)
        @info "Download succeeded from $http_url"
        mv(tmp, file)
        if !isfile(file)
          throw("!!!")
        end
        true
      catch e
        @info("Download failed[$(e.msg)].")
        false
      end
    end
    if !get("https://$url")
      @info "Trying non-https download"
      if !get("http://$url")
        throw("Cannot download GR.  Check internet connection.")
      end
    end

    if os == :Windows
      home = (VERSION < v"0.7-") ? JULIA_HOME : Sys.BINDIR
      @info "Unpack $file"
      success(`$home/7z x $file -y`)
      rm(file)
      tarball = tarball[1:end-3]
      @info "Unpack $tarball"
      success(`$home/7z x $tarball -y -ttar`)
      rm(tarball)
    else
      @info "Unpack $tarball"
      run(`tar xzf $file`)
      rm(file)
    end
  end

  if os == :Darwin
    app = joinpath("gr", "Applications", "GKSTerm.app")
    run(`/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $app`)
    try
      @eval import QML
      if Pkg.installed("QML") != nothing
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
