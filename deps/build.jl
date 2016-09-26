import Compat
if "GRDIR" in keys(ENV)
    have_dir = true
elseif isdir(joinpath(homedir(), "gr"), "fonts")
    have_dir = true
else
    have_dir = false
    for d in ("/opt", "/usr/local", "/usr")
        if isdir(joinpath(d, "gr", "fonts"))
            have_dir = true
            break
        end
    end
end
if !have_dir
  version = v"0.20.0"
  try
    v = Pkg.installed("GR")
    if string(v)[end:end] == "+"
      version = "latest"
    end
  end
  if VERSION > v"0.5-"
    if Sys.KERNEL == :NT
      os = :Windows
    else
      os = Sys.KERNEL
    end
  else
    os = OS_NAME
  end
  const arch = Sys.ARCH
  if os == :Linux && arch == :x86_64
    if isfile("/etc/debian_version")
      id = Compat.readstring(Compat.pipeline(`lsb_release -i`, `cut -f2`))[1:end-1]
      if id in ("Debian", "Ubuntu")
        os = id
      end
    end
  end
  tarball = "gr-$version-$os-$arch.tar.gz"
  if !isfile("downloads/$tarball")
    info("Downloading pre-compiled GR $version $os binary")
    mkpath("downloads")
    download("http://gr-framework.org/downloads/$tarball", "downloads/$tarball")
    if os == :Windows
      success(`$JULIA_HOME/7z x downloads/$tarball -y`)
      rm("downloads/$tarball")
      tarball = tarball[1:end-3]
      success(`$JULIA_HOME/7z x $tarball -y -ttar`)
      rm("$tarball")
    else
      run(`tar xzf downloads/$tarball`)
      rm("downloads/$tarball")
    end
  end
end
