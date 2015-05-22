const version = v"0.13.0"
const gr = "gr-$version"
const os = OS_NAME
const tarball = "gr-$version-$os.tar.gz"

if !isfile("downloads/$tarball")
    info("Downloading pre-compiled GR $version binary")
    mkpath("downloads")
    download("http://gr-framework.org/downloads/$tarball", "downloads/$tarball")
    run(`tar xzf downloads/$tarball`)
end
