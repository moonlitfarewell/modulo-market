import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKET = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text(encoding="utf-8")
MODERN = (ROOT / "AddOns/ModuloMarket/ModernUI.lua").read_text(encoding="utf-8")


def _normalize(value):
    match = re.search(r"\|c([0-9a-fA-F]{8})", value or "")
    if not match:
        match = re.fullmatch(r"#?([0-9a-fA-F]{8})", value or "")
    if not match:
        match = re.search(r"\|cff([0-9a-fA-F]{6})", value or "")
    if not match:
        match = re.fullmatch(r"#?([0-9a-fA-F]{6})", value or "")
    if not match:
        return "ffffffff"
    value = match.group(1).lower()
    return "ff" + value if len(value) == 6 else value


def test_quality_hex_contract_always_returns_alpha_plus_rgb():
    assert 'local function NormalizeItemQualityHex(value)' in MARKET
    assert 'if #hex == 6 then return "ff" .. hex end' in MARKET
    assert 'return "ffffffff"' in MARKET
    assert 'local hex = NormalizeItemQualityHex(rgb)' in MARKET
    assert 'local hex = NormalizeItemQualityHex(color.hex)' in MARKET


def test_wow_markup_preserves_names_starting_with_hexadecimal_characters():
    qualities = ["9d9d9d", "ffffff", "1eff00", "0070dd", "a335ee", "ff8000"]
    names = ["A Head Rag", "7 Pound Yellowtail", "9-60 Battery Pack", "Empresses' Spire"]
    for rgb in qualities:
        alpha_rgb = _normalize(rgb)
        assert len(alpha_rgb) == 8
        for name in names:
            markup = "|c" + alpha_rgb + name + "|r"
            parsed = re.fullmatch(r"\|c([0-9a-fA-F]{8})(.*?)\|r", markup)
            assert parsed is not None
            assert parsed.group(1) == alpha_rgb
            assert parsed.group(2) == name


def test_blizzard_eight_digit_and_rgb_only_values_are_normalized():
    assert _normalize("|cffa335ee") == "ffa335ee"
    assert _normalize("|cff1eff00") == "ff1eff00"
    assert _normalize("a335ee") == "ffa335ee"
    assert _normalize("#0070dd") == "ff0070dd"
    assert _normalize("not-a-colour") == "ffffffff"


def test_every_item_name_display_uses_the_shared_formatter():
    assert 'return "|c" .. GetItemQualityHex(itemID) .. GetItemName(item) .. "|r"' in MARKET
    assert MARKET.count('SetText(GetItemDisplayName(item))') >= 4
    assert 'UI.GetItemDisplayName and UI.GetItemDisplayName(item)' in MODERN
    assert 'function UI.GetModernItemName(item) return item and GetItemDisplayName(item) or "" end' in MARKET


def test_quality_lookup_remains_passive():
    block = MARKET.split("local itemQualityCache = {}", 1)[1].split("local function GetItemDisplayName", 1)[0]
    assert "GetItemInfoCompat" in block
    assert "ITEM_QUALITY_COLORS" in block
    assert "RequestLoadItemDataByID" not in block
    assert "ContinueOnItemLoad" not in block
