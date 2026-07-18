###################
# Base stage
FROM docker.io/library/alpine:latest as base

ARG DEBIAN_FRONTEND

WORKDIR /wd

COPY src/ src/
COPY .python-version pyproject.toml README.md uv.lock ./

RUN  uv sync --frozen --no-dev


###################
# QA stage
FROM base AS qa

ARG DEBIAN_FRONTEND

WORKDIR /wd

RUN apt-get --no-install-recommends install -y \
    git

# fore unit tests
COPY tests/ tests/

# copy config files required for pre-commit
COPY .pre-commit-config.yaml .gitignore .sqlfluff .sqlfluffignore ./

# TODO check
RUN  uv sync --frozen --group qa

# pre-commit requires git initialised and files added
RUN git init . && git add --all

# TODO check
RUN . .venv/bin/activate && pre-commit run --all


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
