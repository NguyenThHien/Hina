from metrics import cer, wer


def test_cer_wer_known_values():
    assert cer("nhà thuốc", "nhà thuốc") == 0
    assert cer("abcd", "abxd") == 0.25
    assert cer("", "abc") == 3  # ref rỗng không chia 0
    assert wer("đọc giúp tôi", "đọc giúp") == 1 / 3
    assert cer("thuốc", "thuoc") == 0.2  # lỗi dấu tiếng Việt được tính (1/5 ký tự)
