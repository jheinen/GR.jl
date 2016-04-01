have_env = "GRDIR" in keys(ENV)
if !have_env && !isdir("/usr/local/gr") && !isdir(joinpath(homedir(),"gr"))
  version = v"0.18.0"
  try
    v = Pkg.installed("GR")
    if string(v)[end:end] == "+"
      version = "latest"
    end
  end
  const os = OS_NAME
  const arch = Sys.ARCH
  tarball = "gr-$version-$os-$arch.tar.gz"
  if !isfile("downloads/$tarball")
    info("Downloading pre-compiled GR $version binary")
    mkpath("downloads")
    download("http://gr-framework.org/downloads/$tarball", "downloads/$tarball")
    @windows_only begin
      success(`$JULIA_HOME/7z x downloads/$tarball -y`)
      rm("downloads/$tarball")
      tarball = tarball[1:end-3]
      success(`$JULIA_HOME/7z x $tarball -y -ttar`)
      rm("$tarball")
    end
    @unix_only begin
      run(`tar xzf downloads/$tarball`)
      rm("downloads/$tarball")
    end
  end
end
