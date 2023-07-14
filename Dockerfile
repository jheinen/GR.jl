FROM jupyter/base-notebook
USER root
# install Julia packages in /opt/julia instead of ${HOME}
ENV JULIA_DEPOT_PATH=/opt/julia
# Julia dependencies
RUN apt-get update && apt-get install -my wget curl gnupg && \
    wget https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.2-linux-x86_64.tar.gz && \
    tar -xzvf julia-1.9.2-linux-x86_64.tar.gz && ls && \
    cp -R julia-1.9.2/* /usr && \
    rm -rf ${HOME}/julia-1.9.2*
# Show Julia where conda libraries are
RUN echo "push!(Libdl.DL_LOAD_PATH, \"${CONDA_DIR}/lib\")" >> /usr/etc/julia/juliarc.jl && \
    # Create JULIA_DEPOT_PATH
    mkdir $JULIA_DEPOT_PATH && \
    chown -R $NB_USER:users $JULIA_DEPOT_PATH
RUN apt-get install -my libnlopt0
# GR3 dependencies
RUN apt-get install -my xvfb
# PackageCompiler dependencies
RUN apt-get install -my gcc
USER $NB_USER
# copy example notebooks and scripts
COPY examples/*.ipynb work/
COPY examples/snoop.jl work/
COPY scripts/docker-xvfb-run /usr/bin/xvfb-run
# Julia packages
RUN julia -E 'using Pkg; pkg"add GR IJulia PackageCompiler CSV HTTP JSON"' && \
    # precompile Julia packages \
    julia -e 'using GR' && \
    julia -e 'using IJulia' && \
    julia -e 'using PackageCompiler' && \
    julia -e 'using CSV' && \
    julia -e 'import HTTP' && \
    julia -e 'import JSON' && \
    # move kernelspec out of home \
    mv ${HOME}/.local/share/jupyter/kernels/julia* ${CONDA_DIR}/share/jupyter/kernels/ && \
    chmod -R go+rx ${CONDA_DIR}/share/jupyter && \
    rm -rf ${HOME}/.local
ENTRYPOINT ["/bin/sh", "-c", "exec xvfb-run $0 $@"]
CMD ["jupyter", "notebook"]
