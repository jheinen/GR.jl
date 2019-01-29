FROM jupyter/base-notebook
USER root
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia
# Julia dependencies
RUN apt-get update && apt-get install -my wget curl gnupg && \
    wget https://julialang-s3.julialang.org/bin/linux/x64/1.1/julia-1.1.0-linux-x86_64.tar.gz && \
    tar -xzvf julia-1.1.0-linux-x86_64.tar.gz && ls && \
    cp -R julia-1.1.0/* /usr && \
    rm -rf $HOME/julia-1.1.0*
    # Show Julia where conda libraries are
RUN echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /usr/etc/julia/juliarc.jl && \
    # Create JULIA_DEPOT_PATH
    mkdir $JULIA_DEPOT_PATH && \
    chown -R $NB_USER:users $JULIA_DEPOT_PATH
RUN apt-get install -my libnlopt0
# GR3 dependencies
#RUN apt-get install -my libxt6 libxrender1 libgl1-mesa-glx libqt5widgets5
USER $NB_USER
# Julia packages
RUN julia -E 'using Pkg; pkg"add GR IJulia"' && \
    # precompile Julia packages \
    julia -e 'using GR' && \
    julia -e 'using IJulia' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local
