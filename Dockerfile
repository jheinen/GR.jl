FROM jupyter/base-notebook
USER root
# Julia dependencies
RUN arch=$(arch | sed 's/arm64/aarch64/') && \
    dir=$(echo ${arch} | sed 's/x86_64/x64/') && \
    apt-get update && apt-get install -my wget curl gnupg && \
    wget https://julialang-s3.julialang.org/bin/linux/${dir}/1.12/julia-1.12.1-linux-${arch}.tar.gz && \
    tar -xzvf julia-1.12.1-linux-${arch}.tar.gz && ls && \
    cp -R julia-1.12.1/* /usr && \
    rm -rf ${HOME}/julia-1.12.1*
RUN apt-get install -my libnlopt0
# GR3 dependencies
RUN apt-get install -my xvfb
USER $NB_USER
# copy example notebooks and scripts
COPY examples/*.ipynb work/
COPY scripts/docker-xvfb-run /usr/bin/xvfb-run
# Julia packages
RUN julia -E 'using Pkg; pkg"add GR IJulia"'
ENTRYPOINT ["/bin/sh", "-c", "exec xvfb-run $0 $@"]
CMD ["jupyter", "notebook"]
