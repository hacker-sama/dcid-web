from types import SimpleNamespace

from app.clients import llm_client


def _settings():
    return SimpleNamespace(
        lm_studio_model="qwen2.5:1.5b",
        vision_model="qwen2.5vl:3b",
    )


def test_text_rag_uses_lightweight_model(monkeypatch):
    monkeypatch.setattr(llm_client, "get_settings", _settings)

    assert llm_client.get_model_name() == "qwen2.5:1.5b"


def test_attached_image_uses_vision_model(monkeypatch):
    monkeypatch.setattr(llm_client, "get_settings", _settings)

    assert llm_client.get_model_name("data:image/png;base64,AAAA") == "qwen2.5vl:3b"
