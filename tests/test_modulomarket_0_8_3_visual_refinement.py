from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
UI = (ROOT / "AddOns/ModuloMarket/MarketUI.lua").read_text()
CORE = (ROOT / "AddOns/ModuloMarket/Core.lua").read_text()
TOC = (ROOT / "AddOns/ModuloMarket/ModuloMarket.toc").read_text()
MANIFEST = json.loads((ROOT / "MANIFEST.json").read_text())


def test_item_role_and_item_type_are_distinct_controls():
    assert 'UI.roleLabel = AddLabel(frame, "Item role"' in UI
    assert '{ text = "All item roles", value = "all"' in UI
    assert 'UI.itemTypeLabel = AddLabel(frame, "Item Types"' in UI
    assert 'UI.itemTypeDropdown = CreateDropdown(frame, 230, 32, -448' in UI
    assert 'local showItemTypeFilter = tab == "market"' in UI
    assert 'if matches and build.tab == "market" and build.itemTypeFilter ~= "all"' in UI


def test_item_type_filter_uses_client_class_metadata_not_item_name_guesses():
    assert "local function GetItemClassID(itemID, requestLoad)" in UI
    assert "info.classID or info.itemClassID" in UI
    assert "local ok, itemName, itemLink, quality, itemLevel, requiredLevel, itemClass" in UI
    assert "local function MatchesItemType(itemID, filter)" in UI
    assert 'if filter == "consumables" then return classID == 0 end' in UI
    assert 'if filter == "equipment" then return classID == 2 or classID == 4 end' in UI
    assert 'if filter == "tradeGoods" then return classID == 7 end' in UI
    assert 'if filter == "other" then' in UI
    assert "if not classID then return false end" in UI
    assert "GetItemName(itemID)" not in UI[UI.index("local function MatchesItemType"):UI.index("local function GetLowSupplyThreshold")]


def test_item_type_metadata_loading_is_bounded_and_reuses_existing_item_events():
    assert "UI.itemClassRequested[itemID] = true" in UI
    assert "local function StepItemClassWarmup()" in UI
    assert "while attempted < 10 and index <= #order do" in UI
    assert "StepItemClassWarmup()" in UI
    assert "api.RequestLoadItemDataByID" in UI
    assert "vendorInfoEvents:RegisterEvent(\"GET_ITEM_INFO_RECEIVED\")" in UI
    assert 'pcall(vendorInfoEvents.RegisterEvent, vendorInfoEvents, "ITEM_DATA_LOAD_RESULT")' in UI
    assert "UI.itemTypeRefreshDueAt = Now() + 0.25" in UI
    assert "and not UI.catalogBuild and not UI.economicsIndexBuild" in UI
    assert "and not UI.viewBuild and not UI.rankSort then" in UI
    assert "UI.itemClassFailed[itemID] = true" in UI


def test_item_type_filter_state_is_retained_per_tab_and_not_applied_to_recipe_rows():
    assert "UI.tabFilterState[previousTab].itemType = UI.itemTypeFilter" in UI
    assert 'UI.itemTypeFilter = saved.itemType or "all"' in UI
    assert "if matches and build.tab == \"market\" and build.itemTypeFilter ~= \"all\"" in UI
    assert "if matches and isCrafting and build.itemRoleFilter ~= \"all\"" in UI


def test_all_items_left_column_spacing_keeps_filters_and_data_card_separate():
    assert "UI.itemTypeDropdown = CreateDropdown(frame, 230, 32, -448" in UI
    assert 'UI.marketQuickFilterHeading = AddLabel(frame, "OPTIONS", 30, -490' in UI
    assert "local y = -516 - ((i - 1) * 24)" in UI
    assert "AddPanelBorder(26, -620, 244, 176)" in UI
    assert 'UI.dataHeading = AddLabel(frame, "Data", 36, -628' in UI
    assert 'CreateDropdown(frame, 220, 36, -752' in UI


def test_title_and_typography_refinement_preserve_existing_layout_density():
    assert 'local titlePlate =' not in UI
    assert 'frame.TitleText:SetPoint("CENTER", frame, "TOP", 0, -27)' in UI
    assert "local function IncreaseFontSize(fontString, delta)" in UI
    assert "IncreaseFontSize(fs, 1)" in UI
    assert "IncreaseFontSize(header.label, 1)" in UI
    assert 'UI.detailEconomics = UI.detailScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")' in UI
    assert "rowHeight = 24" in UI
    assert "visibleCount = 25" in UI


def test_selected_item_inspector_uses_larger_icon_and_more_readable_values():
    assert "UI.detailIcon:SetSize(48, 48)" in UI
    assert 'UI.detailName = AddLabel(frame, "Choose an item", 1200, -204, 208, 30, "GameFontNormalLarge")' in UI
    assert 'local function AddDetailRowLabel' in UI
    assert 'local function AddDetailRowValue' in UI
    assert '"GameFontHighlightLarge"' in UI
    assert 'UI.historyText = AddLabel(UI.detailFooter, "", 6, -32, 268, 54, "GameFontHighlight")' in UI


def test_existing_six_tabs_and_market_engine_boundaries_remain_unchanged():
    tab_block = UI.split("local tabSpecs = {", 1)[1].split("local tabX", 1)[0]
    for key in ['"market"', '"economics"', '"crafts"', '"materials"', '"low"', '"history"']:
        assert key in tab_block
    assert "My Crafts" not in tab_block
    assert "MM.MarketEngine" not in UI
    assert "backgroundOpacity" in UI


def test_release_versions_and_manifest_inventory_align():
    assert 'MM.version = "0.9.5"' in CORE
    assert '## Version: 0.9.5' in TOC
    assert MANIFEST["version"] == "0.9.5"
    assert "MODULOMARKET-RUNTIME-AUDIT-0.8.3.md" in MANIFEST["files"]
    assert "tests/test_modulomarket_0_8_3_visual_refinement.py" in MANIFEST["files"]
    assert MANIFEST["file_count"] == len(MANIFEST["files"])
