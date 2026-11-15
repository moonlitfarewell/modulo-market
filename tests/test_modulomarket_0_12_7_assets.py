from pathlib import Path
import hashlib
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AddOns" / "ModuloMarket"
NAMES = ["check", "close", "cancel", "refresh", "chevron-down", "search"]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def test_original_ui_assets_have_editable_sources_and_provenance():
    assert (ROOT / "ASSET-PROVENANCE.md").exists()
    assert (ROOT / "tools/assets/render_modulomarket_icons.py").exists()
    for name in NAMES:
        assert (ROOT / "assets/ui-icons" / f"{name}.svg").is_file()
        with Image.open(ADDON / "Textures" / f"{name}.tga") as image:
            assert image.format == "TGA"
            assert image.mode == "RGBA"
            assert image.size == (64, 64)
            assert image.getchannel("A").getbbox() is not None

def test_original_ui_asset_renderer_is_deterministic():
    paths = [ADDON / "Textures" / f"{name}.tga" for name in NAMES]
    before = [sha(path) for path in paths]
    subprocess.run([sys.executable, str(ROOT / "tools/assets/render_modulomarket_icons.py")], check=True)
    after = [sha(path) for path in paths]
    assert after == before
