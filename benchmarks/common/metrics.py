from collections.abc import Sequence


def _edit_distance(a: Sequence, b: Sequence) -> int:
    prev = list(range(len(b) + 1))
    for i, x in enumerate(a, 1):
        cur = [i]
        for j, y in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (x != y)))
        prev = cur
    return prev[-1]


def cer(ref: str, hyp: str) -> float:
    """Character error rate (OCR recognition, ASR)."""
    return _edit_distance(ref, hyp) / max(len(ref), 1)


def wer(ref: str, hyp: str) -> float:
    """Word error rate; tiếng Việt tách theo khoảng trắng (âm tiết)."""
    r = ref.split()
    return _edit_distance(r, hyp.split()) / max(len(r), 1)
