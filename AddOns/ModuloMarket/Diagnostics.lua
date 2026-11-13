local MM = _G.ModuloMarket
if not MM then return end

local API = _G.C_TradeSkillUI
local MAX_RECIPES = 500
local MAX_REAGENTS_PER_SLOT = 100

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil, "API_MISSING"
    end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then
        return nil, tostring(a)
    end
    return a, nil, b, c, d
end

local function Value(v)
    if v == nil then return "nil" end
    if type(v) == "boolean" then return v and "true" or "false" end
    if type(v) == "table" then return "<table>" end
    return tostring(v)
end

local function Add(lines, key, value)
    lines[#lines + 1] = tostring(key) .. ": " .. Value(value)
end

local function SortedKeys(t)
    local keys = {}
    if type(t) == "table" then
        for k in pairs(t) do keys[#keys + 1] = k end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function AddAPIStatus(lines, name)
    local fn = API and API[name]
    lines[#lines + 1] = "  " .. name .. " = " .. type(fn)
end

local function GetClientInfo()
    local version, build, date, interface = GetBuildInfo()
    return version, build, date, interface
end

local function GetProfessionLines(lines)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "PROFESSION SKILL-LINE ENUMERATION"
    local ids, err = SafeCall(API and API.GetAllProfessionTradeSkillLines)
    if type(ids) ~= "table" then
        lines[#lines + 1] = "GetAllProfessionTradeSkillLines: " .. tostring(err or "no table")
        return
    end
    lines[#lines + 1] = "Count: " .. tostring(#ids)
    for i = 1, #ids do
        local id = ids[i]
        local name = SafeCall(API and API.GetTradeSkillDisplayName, id)
        local info = SafeCall(API and API.GetProfessionInfoBySkillLineID, id)
        local skill = type(info) == "table" and info.skillLevel or nil
        local maxSkill = type(info) == "table" and info.maxSkillLevel or nil
        lines[#lines + 1] = string.format("  [%d] skillLineID=%s | name=%s | skill=%s/%s",
            i, Value(id), Value(name), Value(skill), Value(maxSkill))
    end
end

local function AddReagentSlots(lines, schematic)
    local slots = schematic and schematic.reagentSlotSchematics
    if type(slots) ~= "table" then
        lines[#lines + 1] = "  Reagent slots: unavailable"
        return
    end
    lines[#lines + 1] = "  Reagent slot count: " .. tostring(#slots)
    for i = 1, #slots do
        local slot = slots[i]
        lines[#lines + 1] = string.format("  SLOT %d", i)
        Add(lines, "    required", slot.required)
        Add(lines, "    quantityRequired", slot.quantityRequired)
        Add(lines, "    dataSlotIndex", slot.dataSlotIndex)
        Add(lines, "    slotIndex", slot.slotIndex)
        Add(lines, "    dataSlotType", slot.dataSlotType)
        Add(lines, "    reagentType", slot.reagentType)
        Add(lines, "    hiddenInCraftingForm", slot.hiddenInCraftingForm)
        Add(lines, "    orderSource", slot.orderSource)
        if type(slot.variableQuantities) == "table" then
            lines[#lines + 1] = "    variableQuantities fields:"
            for _, key in ipairs(SortedKeys(slot.variableQuantities)) do
                lines[#lines + 1] = "      " .. tostring(key) .. "=" .. Value(slot.variableQuantities[key])
            end
        else
            Add(lines, "    variableQuantities", slot.variableQuantities)
        end
        local reagents = slot.reagents
        if type(reagents) == "table" then
            local count = math.min(#reagents, MAX_REAGENTS_PER_SLOT)
            lines[#lines + 1] = "    reagent choices: " .. tostring(#reagents)
            for j = 1, count do
                local reagent = reagents[j]
                if type(reagent) == "table" then
                    lines[#lines + 1] = string.format("      [%d] itemID=%s name=%s hyperlink=%s",
                        j, Value(reagent.itemID), Value(reagent.name), Value(reagent.hyperlink))
                else
                    lines[#lines + 1] = "      [" .. j .. "] " .. Value(reagent)
                end
            end
            if #reagents > count then
                lines[#lines + 1] = "      ... truncated for safety"
            end
        else
            lines[#lines + 1] = "    reagent choices: unavailable"
        end
    end
end

local function AddRecipe(lines, recipeID)
    local info, infoErr = SafeCall(API and API.GetRecipeInfo, recipeID)
    local schematic, schematicErr = SafeCall(API and API.GetRecipeSchematic, recipeID, false)
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("RECIPE %s", Value(recipeID))
    if type(info) == "table" then
        Add(lines, "  name", info.name)
        Add(lines, "  learned", info.learned)
        Add(lines, "  craftable", info.craftable)
        Add(lines, "  disabled", info.disabled)
        Add(lines, "  recipeID", info.recipeID)
        Add(lines, "  skillLineAbilityID", info.skillLineAbilityID)
        Add(lines, "  categoryID", info.categoryID)
        Add(lines, "  supportsQualities", info.supportsQualities)
        Add(lines, "  hasSingleItemOutput", info.hasSingleItemOutput)
        Add(lines, "  canCreateMultiple", info.canCreateMultiple)
        Add(lines, "  isGatheringRecipe", info.isGatheringRecipe)
        Add(lines, "  isEnchantingRecipe", info.isEnchantingRecipe)
        Add(lines, "  isSalvageRecipe", info.isSalvageRecipe)
    else
        lines[#lines + 1] = "  GetRecipeInfo error: " .. tostring(infoErr)
    end
    if type(schematic) == "table" then
        Add(lines, "  schematic.name", schematic.name)
        Add(lines, "  outputItemID", schematic.outputItemID)
        Add(lines, "  quantityMin", schematic.quantityMin)
        Add(lines, "  quantityMax", schematic.quantityMax)
        Add(lines, "  recipeType", schematic.recipeType)
        Add(lines, "  isRecraft", schematic.isRecraft)
        local outputData, outputErr = SafeCall(API and API.GetRecipeOutputItemData, recipeID)
        if type(outputData) == "table" then
            Add(lines, "  outputData.itemID", outputData.itemID)
            Add(lines, "  outputData.hyperlink", outputData.hyperlink)
            Add(lines, "  outputData.icon", outputData.icon)
        else
            lines[#lines + 1] = "  GetRecipeOutputItemData error: " .. tostring(outputErr)
        end
        AddReagentSlots(lines, schematic)
    else
        lines[#lines + 1] = "  GetRecipeSchematic error: " .. tostring(schematicErr)
    end
end

local function GetCurrentProfession(lines)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "ACTIVE PROFESSION / CURRENT RECIPE CONTEXT"
    local base, baseErr = SafeCall(API and API.GetBaseProfessionInfo)
    if type(base) == "table" then
        Add(lines, "Profession name", base.professionName)
        Add(lines, "Profession ID", base.professionID)
        Add(lines, "Skill", tostring(Value(base.skillLevel)) .. "/" .. tostring(Value(base.maxSkillLevel)))
        Add(lines, "Source counter", base.sourceCounter)
        Add(lines, "Is primary profession", base.isPrimaryProfession)
        Add(lines, "Expansion", base.expansionName)
    else
        lines[#lines + 1] = "GetBaseProfessionInfo error: " .. tostring(baseErr)
    end

    local ids, idsErr = SafeCall(API and API.GetFilteredRecipeIDs)
    if type(ids) ~= "table" then
        lines[#lines + 1] = "GetFilteredRecipeIDs error: " .. tostring(idsErr)
        return
    end
    local count = #ids
    lines[#lines + 1] = "Filtered recipe count: " .. tostring(count)
    if count > MAX_RECIPES then
        lines[#lines + 1] = "WARNING: recipe list capped at " .. tostring(MAX_RECIPES)
    end
    local limit = math.min(count, MAX_RECIPES)
    for i = 1, limit do
        AddRecipe(lines, ids[i])
    end
end

local function BuildReport(mode)
    local lines = {}
    lines[#lines + 1] = "MODULO MARKET DIAGNOSTICS"
    lines[#lines + 1] = "Report mode: " .. tostring(mode or "FULL_CURRENT_PROFESSION")
    lines[#lines + 1] = "Addon version: " .. tostring(MM.version)
    local version, build, buildDate, interface = GetClientInfo()
    Add(lines, "Client version", version)
    Add(lines, "Client build", build)
    Add(lines, "Client date", buildDate)
    Add(lines, "Interface", interface)
    if type(_G.date) == "function" then
        lines[#lines + 1] = "Timestamp: " .. _G.date("%Y-%m-%d %H:%M:%S")
    else
        lines[#lines + 1] = "Timestamp: unavailable (date API missing)"
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "TRADE SKILL API AVAILABILITY"
    local apiNames = {
        "GetAllProfessionTradeSkillLines",
        "GetTradeSkillDisplayName",
        "GetProfessionInfoBySkillLineID",
        "GetBaseProfessionInfo",
        "GetFilteredRecipeIDs",
        "GetAllRecipeIDs",
        "GetRecipeInfo",
        "GetRecipeSchematic",
        "GetRecipeOutputItemData",
        "GetProfessionInfoByRecipeID",
        "IsRecipeInSkillLine",
        "OpenTradeSkill",
    }
    for i = 1, #apiNames do AddAPIStatus(lines, apiNames[i]) end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "AUCTION HOUSE API AVAILABILITY (NO REQUESTS SENT)"
    local auctionHouse = _G.C_AuctionHouse
    local auctionNames = {
        "SendBrowseQuery",
        "RequestMoreBrowseResults",
        "GetBrowseResults",
        "HasFullBrowseResults",
        "IsThrottledMessageSystemReady",
    }
    for i = 1, #auctionNames do
        lines[#lines + 1] = "  C_AuctionHouse." .. auctionNames[i] .. " = " .. type(auctionHouse and auctionHouse[auctionNames[i]])
    end

    if mode == "LINES" or mode == "FULL" then
        GetProfessionLines(lines)
    end
    if mode ~= "LINES" then
        GetCurrentProfession(lines)
    end
    if MM.Recipes and MM.Recipes.GetProfessionSummary then
        local summary = MM.Recipes.GetProfessionSummary()
        lines[#lines + 1] = ""
        lines[#lines + 1] = "MARKET RECIPE CAPTURE"
        Add(lines, "Character", summary.character)
        Add(lines, "Captured professions", #summary.professions)
        Add(lines, "Known recipes", summary.recipeCount)
        local schemaVersion = MM.Recipes.GetRecipeSnapshotSchemaVersion
            and MM.Recipes.GetRecipeSnapshotSchemaVersion() or "unknown"
        Add(lines, "Required recipe snapshot schema", schemaVersion)
        local characterStore = MM.db and MM.db.professionRecipesByCharacter
            and MM.db.professionRecipesByCharacter[summary.character]
        if type(characterStore) == "table" then
            lines[#lines + 1] = "Current-character profession snapshot records:"
            for professionID, profession in pairs(characterStore) do
                if tonumber(professionID) and type(profession) == "table" then
                    local storedSchema = tonumber(profession.snapshotSchemaVersion)
                    local current = storedSchema == tonumber(schemaVersion)
                    lines[#lines + 1] = string.format(
                        "  %s (%s): schema=%s [%s], generation=%s, addonBuild=%s, recipes=%s, capturedAt=%s",
                        tostring(profession.professionName or "Profession"), tostring(professionID),
                        tostring(storedSchema or "legacy/missing"), current and "CURRENT" or "STALE — recapture required",
                        tostring(profession.snapshotGeneration or "unknown"), tostring(profession.snapshotBuild or "unknown"),
                        tostring(profession.recipeCount or 0), tostring(profession.capturedAt or "unknown"))
                end
            end
        else
            lines[#lines + 1] = "Current-character profession snapshot records: none"
        end
        local capture = MM.Recipes.GetCaptureStatus and MM.Recipes.GetCaptureStatus() or {}
        for event, enabled in pairs(capture.events or {}) do
            lines[#lines + 1] = "  capture event " .. tostring(event) .. "=" .. tostring(enabled)
        end
        Add(lines, "Capture active", capture.active)
        Add(lines, "Capture last result", capture.lastCaptureReason)
        Add(lines, "Unchanged captures skipped", capture.skippedUnchanged)
        Add(lines, "Capture retry pass", capture.retryPass or 0)
        Add(lines, "Unresolved recipe records", capture.unresolved or 0)
        if capture.active then
            Add(lines, "Capture progress", tostring(capture.processed or 0) .. "/" .. tostring(capture.total or 0))
        end
        for _, profession in ipairs(summary.professions) do
            lines[#lines + 1] = string.format("  %s: %d recipes, skill %s/%s, full list=%s",
                tostring(profession.name), tonumber(profession.recipeCount) or 0,
                tostring(profession.skill or "?"), tostring(profession.maxSkill or "?"),
                tostring(profession.listComplete == true))
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "END OF REPORT"
    return table.concat(lines, "\n")
end

local function CreateButton(parent, text, width, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function CreateUI()
    if MM.Diagnostics and MM.Diagnostics.frame then return MM.Diagnostics.frame end
    local frame = CreateFrame("Frame", "ModuloMarketDiagnosticsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(760, 560)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Modulo Market Diagnostics")
    frame:Hide()

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -34)
    subtitle:SetText("Read-only client inspection. Select output, then Ctrl+C.")

    local output = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    output:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -112)
    output:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 16)

    local edit = CreateFrame("EditBox", nil, output)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(690)
    edit:SetHeight(420)
    edit:SetPoint("TOPLEFT", output, "TOPLEFT", 0, 0)
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local _, lineCount = text:gsub("\n", "")
        self:SetHeight(math.max(420, (lineCount + 2) * 15))
        output:SetScrollChild(self)
    end)
    output:SetScrollChild(edit)

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -86)
    status:SetText("Ready.")

    local function ShowReport(mode)
        local ok, report = pcall(BuildReport, mode)
        if not ok then
            report = "MODULO MARKET DIAGNOSTICS\nFATAL REPORT ERROR:\n" .. tostring(report)
        end
        edit:SetText(report)
        edit:SetCursorPosition(0)
        edit:HighlightText()
        status:SetText("Report generated. Click output, Ctrl+A, Ctrl+C.")
    end

    CreateButton(frame, "Full Current Profession", 170, 16, -58, function() ShowReport("FULL") end)
    CreateButton(frame, "Profession Lines", 125, 192, -58, function() ShowReport("LINES") end)
    CreateButton(frame, "Active Profession", 130, 325, -58, function() ShowReport("ACTIVE") end)
    CreateButton(frame, "Select All", 90, 465, -58, function()
        edit:SetFocus()
        edit:HighlightText()
        status:SetText("All selected. Press Ctrl+C.")
    end)
    CreateButton(frame, "Close", 70, 565, -58, function() frame:Hide() end)

    MM.Diagnostics = MM.Diagnostics or {}
    MM.Diagnostics.frame = frame
    MM.Diagnostics.output = edit
    MM.Diagnostics.status = status
    return frame
end

MM.Diagnostics = MM.Diagnostics or {}
MM.Diagnostics.BuildReport = BuildReport
MM.Diagnostics.Toggle = function()
    local frame = CreateUI()
    if frame:IsShown() then frame:Hide() else
        frame:Show()
        local ok, report = pcall(BuildReport, "ACTIVE")
        if ok then
            MM.Diagnostics.output:SetText(report)
            MM.Diagnostics.output:SetCursorPosition(0)
            MM.Diagnostics.output:HighlightText()
            MM.Diagnostics.status:SetText("Initial active-profession report. Press Ctrl+C to copy.")
        else
            MM.Diagnostics.output:SetText("Report error: " .. tostring(report))
        end
    end
end
