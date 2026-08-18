from app.clients.llm_client import _remove_repetition_loops


def test_removes_two_identical_paragraphs() -> None:
    paragraph = "Siết bu lông theo đúng mô-men ghi trên bản vẽ."
    assert _remove_repetition_loops(f"{paragraph}\n\n{paragraph}") == paragraph


def test_removes_two_identical_inline_sentences() -> None:
    sentence = "Kiểm tra nguồn điện trước khi tháo thiết bị."
    assert _remove_repetition_loops(f"{sentence} {sentence}") == sentence


def test_keeps_similar_sentences_with_different_measurements() -> None:
    text = "Trục A dài 42.15 mm. Trục B dài 48 mm."
    assert _remove_repetition_loops(text) == text
