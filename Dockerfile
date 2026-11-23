ARG PYTHON_VERSION=3.12

# ---------- Stage 1 : builder (dépendances + tests) ----------
FROM python:${PYTHON_VERSION}-slim AS builder
WORKDIR /app
COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt \
 && pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt
COPY app.py test_app.py ./
RUN python -m pytest -q

# ---------- Stage 2 : runtime (image finale légère) ----------
FROM python:${PYTHON_VERSION}-slim AS runtime
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
RUN useradd --create-home appuser
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=10s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]