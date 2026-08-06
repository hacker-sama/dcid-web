"""Wrapper gọi Qwen2.5-VL 3B trên Ollama qua API OpenAI-compatible."""

import logging
import os
import re
from typing import Any, Dict, Generator, List, Optional, Tuple

import yaml

logger = logging.getLogger("dcid-ai.llm")


def _load_config() -> Dict[str, Any]:
    """Tải cấu hình từ config.yaml."""
    try:
        with open("config.yaml", "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except Exception:
        return {
            "models": {
                "vision_model": "qwen2.5vl:3b",
                "main_llm_model": "qwen2.5vl:3b",
            },
            "lm_studio": {
                "base_url": "http://ollama:11434/v1",
                "api_key": "ollama",
                "timeout": 60.0,
                "temperature": 0.2,
                "max_tokens": 2048,
            },
        }


def get_openai_client():
    """Khởi tạo OpenAI client kết nối tới local LLM server (LM Studio / Ollama)."""
    from openai import OpenAI

    cfg = _load_config()
    lm_cfg = cfg.get("lm_studio", {})
    return OpenAI(
        base_url=os.getenv("LM_STUDIO_BASE_URL", lm_cfg.get("base_url", "http://ollama:11434/v1")),
        api_key=os.getenv("LM_STUDIO_API_KEY", lm_cfg.get("api_key", "ollama")),
        timeout=lm_cfg.get("timeout", 60.0),
    )


def generate_vision_caption(
    image_base64: str,
    prompt: str,
    model_name: Optional[str] = None,
) -> str:
    """Gọi Qwen2-VL-2B-Instruct để làm Visual Captioner cho ảnh đã crop."""
    cfg = _load_config()
    model = model_name or os.getenv("LM_STUDIO_MODEL") or cfg.get("models", {}).get("vision_model", "qwen2.5vl:3b")

    client = get_openai_client()

    messages = [
        {
            "role": "user",
            "content": [
                {"type": "image_url", "image_url": {"url": image_base64}},
                {"type": "text", "text": prompt},
            ],
        }
    ]

    try:
        logger.info("Goi Qwen2-VL 2B model=%s captioning crop image...", model)
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.1,
            max_tokens=512,
        )
        caption = response.choices[0].message.content or ""
        logger.info("Qwen2-VL 2B caption OK (%d chars): %.100s", len(caption), caption)
        return caption.strip()
    except Exception as exc:
        logger.error("Loi khi goi Qwen2-VL 2B vision captioner: %s", exc)
        return ""


def generate_rag_answer(
    system_prompt: str,
    user_prompt: str,
    model_name: Optional[str] = None,
) -> Tuple[str, str]:
    """Gọi Main Text LLM (Qwen2.5-7B / Gemma-2-9B) để thực hiện suy luận RAG và trả lời người dùng."""
    cfg = _load_config()
    model = model_name or os.getenv("LM_STUDIO_MODEL") or cfg.get("models", {}).get("main_llm_model", "qwen2.5vl:3b")
    lm_cfg = cfg.get("lm_studio", {})

    client = get_openai_client()

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

    try:
        logger.info("Goi Main Text LLM model=%s RAG inference...", model)
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=lm_cfg.get("temperature", 0.2),
            max_tokens=lm_cfg.get("max_tokens", 2048),
        )
        answer = response.choices[0].message.content or ""
        cleaned_answer = re.sub(r"<think>.*?</think>", "", answer, flags=re.DOTALL).strip()
        model_used = response.model or model
        logger.info("Main LLM answer OK (%d chars)", len(cleaned_answer))
        return cleaned_answer, model_used
    except Exception as exc:
        logger.error("Loi khi goi Main Text LLM: %s", exc)
        return f"Lỗi xử lý LLM: {exc}", model or "unknown"


def generate_rag_answer_stream(
    system_prompt: str,
    user_prompt: str,
    model_name: Optional[str] = None,
) -> Generator[str, None, None]:
    """Generator streaming SSE trả về từng token text cho Main Text LLM."""
    cfg = _load_config()
    model = model_name or os.getenv("LM_STUDIO_MODEL") or cfg.get("models", {}).get("main_llm_model", "qwen2.5vl:3b")
    lm_cfg = cfg.get("lm_studio", {})

    client = get_openai_client()

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

    try:
        stream = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=lm_cfg.get("temperature", 0.2),
            max_tokens=lm_cfg.get("max_tokens", 2048),
            stream=True,
        )
        for chunk in stream:
            delta = chunk.choices[0].delta if chunk.choices else None
            if delta and delta.content:
                yield delta.content
    except Exception as exc:
        logger.error("Loi khi stream Main Text LLM: %s", exc)
        yield f"[Lỗi stream: {exc}]"
