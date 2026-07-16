FROM python:3.11-slim

WORKDIR /srv/dcid-ai

# ── Layer 1: torch CPU-only trước (cần --extra-index-url PyTorch) ─────────────
RUN pip install --no-cache-dir \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    "torch==2.3.1+cpu" \
    "torchvision==0.18.1+cpu"

# ── Layer 2: phần còn lại (KHÔNG có paddleocr — service riêng) ───────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── App code ──────────────────────────────────────────────────────────────────
COPY app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
