import sys
import threading
import time
import types
from concurrent.futures import ThreadPoolExecutor

from app.pipeline import embed


def test_concurrent_first_load_creates_one_model(monkeypatch) -> None:
    created = 0
    counter_lock = threading.Lock()

    class FakeSentenceTransformer:
        def __init__(self, _model_name: str) -> None:
            nonlocal created
            with counter_lock:
                created += 1
            time.sleep(0.05)

    fake_module = types.SimpleNamespace(SentenceTransformer=FakeSentenceTransformer)
    monkeypatch.setitem(sys.modules, "sentence_transformers", fake_module)
    embed._load_model.cache_clear()

    with ThreadPoolExecutor(max_workers=4) as pool:
        models = list(pool.map(lambda _index: embed._get_model(), range(4)))

    assert created == 1
    assert all(model is models[0] for model in models)
    embed._load_model.cache_clear()
