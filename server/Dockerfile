FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:0.11.8 /uv /bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
COPY src ./src
RUN uv sync --locked --no-dev
EXPOSE 8000
CMD ["uv", "run", "--no-sync", "uvicorn", "hina.main:app", "--host", "0.0.0.0", "--port", "8000"]
