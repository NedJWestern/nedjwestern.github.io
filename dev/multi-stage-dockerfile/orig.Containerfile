# pass in from `.python-version` file
ARG PYTHON_VERSION

# Needed to avoid errors with automated apt-get and dialog missing etc.
# Adding as ARG as only want it during build time not in final image.
ARG DEBIAN_FRONTEND=noninteractive

#################
# used by all stages
FROM docker.io/library/python:${PYTHON_VERSION}-slim AS py_base

ARG DEBIAN_FRONTEND

WORKDIR /wd

# Set env vars for all layers and final built image
ENV TZ=Australia/Brisbane \
    # warning is a false positive
    POLARS_SKIP_CPU_CHECK=true \
    # prevent warning about hardlinking files
    UV_LINK_MODE=copy \
    PATH="/wd/.venv/bin:$PATH"

# inspiration: https://docs.docker.com/reference/dockerfile/#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# cache packages for fasting local builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    # && apt-get dist-upgrade -y \  TODO restore
    && apt-get --no-install-recommends install -y \
    less \
    # required by LightGBM
    libgomp1 \
    unixodbc-dev

# Install databricks ODBC drivers (Simba Spark)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get --no-install-recommends install -y \
    unzip \
    wget \
    libsasl2-modules \
    libsasl2-modules-gssapi-mit \
    && mkdir /opt/simba && cd /opt/simba \
    && wget --no-verbose https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.8.0/SimbaSparkODBC-2.8.0.1002-Debian-64bit.zip \
    && unzip -o SimbaSparkODBC-2.8.0.1002-Debian-64bit.zip \
    && dpkg -i simbaspark_2.8.0.1002-2_amd64.deb

#################
# stage for containerised development
FROM py_base AS dev_container

ARG DEBIAN_FRONTEND

# required for uv installation
ENV PATH="$HOME/.local/bin:$PATH"

WORKDIR /wd

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get --no-install-recommends install -y \
    curl \
    direnv \
    git \
    vim

# enable direnv
RUN echo 'eval "$(direnv hook bash)"' >> $HOME/.bashrc

# this facilitates upgrading uv within the container
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# command completion for uv
RUN echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc

CMD ["/bin/bash"]


#################
# installed API with all dependencies
FROM py_base AS base

ARG DEBIAN_FRONTEND
ARG UV_INDEX_JFROG_PYPI_USERNAME

WORKDIR /wd

COPY src/ src/
COPY data/ data/
COPY .python-version params.yaml pyproject.toml README.md logging_config.yaml uv.lock ./

# temporary mount so that uv is not in the final image
RUN --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv \
    --mount=type=secret,id=jfrog_pypi_password bash <<EOF
set -eu
echo UV_INDEX_JFROG_PYPI_USERNAME: "$UV_INDEX_JFROG_PYPI_USERNAME"
export UV_INDEX_JFROG_PYPI_PASSWORD=$(head -n 1 /run/secrets/jfrog_pypi_password)
uv sync --frozen --no-dev
EOF


#################
# stage for quality checks
FROM base AS qa

ARG DEBIAN_FRONTEND
ARG UV_INDEX_JFROG_PYPI_USERNAME

WORKDIR /wd

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get --no-install-recommends install -y \
    git

# add "qa" group dependencies including ruff, black etc.
RUN --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv \
    --mount=type=secret,id=jfrog_pypi_password bash <<EOF
set -eu
echo UV_INDEX_JFROG_PYPI_USERNAME: "$UV_INDEX_JFROG_PYPI_USERNAME"
export UV_INDEX_JFROG_PYPI_PASSWORD=$(head -n 1 /run/secrets/jfrog_pypi_password)
uv sync --frozen --no-dev --group qa
EOF

COPY tests/ tests/
# copy config files required for pre-commit
COPY .pre-commit-config.yaml .gitignore .sqlfluff .sqlfluffignore ./

# prevent annoying warning
RUN git config --global init.defaultBranch master

# pre-commit requires git initialised and files added
RUN git init . && git add --all

RUN . .venv/bin/activate && pre-commit run --all


##################
# stage to fetch Solcast data
FROM base AS fetch

ARG DEBIAN_FRONTEND

WORKDIR /wd

# add "fetch" group dependencies
RUN --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv \
    --mount=type=secret,id=jfrog_pypi_password bash <<EOF
set -eu
echo UV_INDEX_JFROG_PYPI_USERNAME: "$UV_INDEX_JFROG_PYPI_USERNAME"
export UV_INDEX_JFROG_PYPI_PASSWORD=$(head -n 1 /run/secrets/jfrog_pypi_password)
uv sync --frozen
EOF

CMD ["python", "src/fetch_solcast/schedule.py"]


##################
# stage for production
FROM base AS prod

ARG DEBIAN_FRONTEND

WORKDIR /wd

RUN --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv \
    --mount=type=secret,id=jfrog_pypi_password bash <<EOF
set -eu
echo UV_INDEX_JFROG_PYPI_USERNAME: "$UV_INDEX_JFROG_PYPI_USERNAME"
export UV_INDEX_JFROG_PYPI_PASSWORD=$(head -n 1 /run/secrets/jfrog_pypi_password)
uv sync --frozen --no-dev
EOF

CMD ["python", "src/drefs_fcst/schedule.py"]
