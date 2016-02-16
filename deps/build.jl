have_env = "GRDIR" in keys(ENV)
if !have_env && !isdir("/usr/local/gr") && !isdir(joinpath(homedir(),"gr"))
  const version = v"0.17.3"
  const gr = "gr-$version"
  const os = OS_NAME
  const arch = Sys.ARCH
  tarball = "gr-$version-$os-$arch.tar.gz"
  if !isfile("downloads/$tarball")
    info("Downloading pre-compiled GR $version binary")
    mkpath("downloads")
    download("http://gr-framework.org/downloads/$tarball", "downloads/$tarball")
    @windows_only begin
      success(`$JULIA_HOME/7z x downloads/$tarball -y`)
      tarball = tarball[1:end-3]
      success(`$JULIA_HOME/7z x $tarball -y -ttar`)
    end
    @unix_only begin
      run(`tar xzf downloads/$tarball`)
    end
    rm("downloads/$tarball")
  end
end
