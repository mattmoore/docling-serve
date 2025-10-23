FROM nvidia/cuda:13.0.1-cudnn-devel-ubuntu24.04

WORKDIR /app

ENV \
    OMP_NUM_THREADS=4 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONIOENCODING=utf-8 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/app-root \
    DOCLING_SERVE_ARTIFACTS_PATH=/opt/app-root/src/.cache/docling/models

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates libxml2-dev libxslt-dev libz-dev

ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin/:$PATH"


COPY --chown=1001:0 ./docling_serve ./docling_serve
COPY --chown=1001:0 ./pyproject.toml ./pyproject.toml
COPY --chown=1001:0 ./uv.lock ./uv.lock
COPY --chown=1001:0 ./.python-version ./.python-version

RUN uv sync --frozen --no-dev --all-extras --no-build-isolation-package=flash-attn


EXPOSE 5001

CMD ["uv", "run", "docling-serve", "run"]
