from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns/ModuloMarket"


def test_diagnostic_setting_name_is_short_and_button_keeps_action_label():
    theme = (ADDON / "Theme.lua").read_text(encoding="utf-8")
    assert 'AddButton("Diagnostic window", "Open Browse Scan / Snapshot",' in theme
    assert 'AddButton("Browse Scan and Snapshot Debug", "Diagnostic window",' not in theme


def test_version_metadata_is_consistent():
    toc = (ADDON / "ModuloMarket.toc").read_text(encoding="utf-8")
    core = (ADDON / "Core.lua").read_text(encoding="utf-8")
    assert "## Version: 0.12.19" in toc
    assert 'MM.version = "0.12.19"' in core
