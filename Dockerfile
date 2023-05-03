FROM jupyter/base-notebook
ARG JULIA_DIR="/opt/julia-1.8.5" 

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    ffmpeg \ 
    curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN curl -L https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz | tar zxv

USER ${NB_UID}
RUN mamba install --yes \
    'matplotlib' 

RUN jupyter notebook -y --generate-config && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "${JULIA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

RUN export PATH=$PATH:${JULIA_DIR}/bin && \
    ${JULIA_DIR}/bin/julia -e 'using Pkg; Pkg.add(["IJulia", "Plots", "PyPlot", "JSON", "BenchmarkTools"])' && \
    ${JULIA_DIR}/bin/julia -e 'using IJulia; IJulia.installkernel("Julia Multi-threaded", env=Dict("JULIA_NUM_THREADS"=> "auto",))'

WORKDIR "${HOME}"

RUN rmdir work

COPY --chown=${NB_UID}:${NB_GID} . .

CMD ["jupyter", "lab", "--notebook-dir=.", "--preferred-dir=./code"]
