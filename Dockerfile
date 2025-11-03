# Stage 1: Build Environment

FROM nvidia/cuda:13.0.1-cudnn-devel-ubuntu24.04 AS builder
COPY --from=ghcr.io/astral-sh/uv:0.9.6 /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  libxml2-dev \
  libxslt-dev \
  libz-dev

WORKDIR /app

ENV DOCLING_ARTIFACTS_PATH=/root/.cache/docling/models

COPY pyproject.toml /app/pyproject.toml
COPY uv.lock /app/uv.lock
COPY .python-version /app/.python-version
COPY docling_serve /app/docling_serve

RUN uv sync --frozen --no-dev --all-extras --compile-bytecode --no-build-isolation-package=flash-attn
RUN uv run docling-tools models download --all


# Stage 2: Runtime Environment

FROM nvidia/cuda:13.0.1-cudnn-runtime-ubuntu24.04
COPY --from=ghcr.io/astral-sh/uv:0.9.6 /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
  tesseract-ocr \
  tesseract-ocr-eng \
  libtesseract-dev \
  libleptonica-dev \
  pkg-config

WORKDIR /app

ENV \
    OMP_NUM_THREADS=4 \
    PYTHONIOENCODING=utf-8 \
    DOCLING_ARTIFACTS_PATH=/root/.cache/docling/models

COPY --from=builder /app /app
COPY --from=builder /root/.cache/docling/models /root/.cache/docling/models
COPY --from=builder /root/.local/share/uv /root/.local/share/uv

EXPOSE 5001

CMD ["uv", "run", "docling-serve", "run"]
