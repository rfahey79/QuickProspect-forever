-- QuickProspect: Warcraft Forever / interface 16001 port.
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetSpellInfo = GetSpellInfo or function(id) return C_Spell.GetSpellName(id) end
local SPELL_DISENCHANT, SPELL_PROSPECT, SPELL_MILL, SPELL_PICK_LOCK = 13262, 31252, 51005, 1804
local COLOR_MILL, COLOR_PROSPECT = {0.20,0.55,1}, {0.52,0.22,1}
local COLOR_DISENCHANT, COLOR_LOCKPICK, COLOR_TOO_HIGH = {0.72,0.25,1}, {0.25,0.75,1}, {1,0.08,0.08}
local ORES = {
    [2770]=20, [2771]=50, [2772]=125, [3858]=175, [10620]=250,
    [23424]=275, [23425]=325, [36909]=350, [36912]=400, [36910]=450,
}

local HERBS = {
    [2447]=1, [765]=1, [2449]=1, [785]=1, [2450]=1, [2452]=1, [2453]=1,
    [3355]=25, [3369]=25, [3356]=25, [3357]=25, [3818]=25, [3820]=25,
    [3821]=75, [3358]=75, [3819]=75, [8831]=75, [8838]=75, [8839]=75,
    [8845]=125, [8846]=125, [13464]=125, [13463]=125, [13465]=125,
    [13466]=175, [13467]=175, [13468]=175, [22785]=225, [22786]=225,
    [22787]=225, [22789]=225, [22790]=225, [22791]=225, [22792]=225,
    [22793]=225, [36901]=275, [36904]=275, [36907]=325, [39970]=325,
    [37921]=325, [36903]=325, [36906]=325, [36905]=325, [36908]=325,
}

local LOCKBOXES = {
    [4632]=1, [4633]=25, [4634]=70, [4636]=125, [4637]=175, [4638]=225,
    [5758]=225, [5759]=225, [5760]=225, [6354]=1, [6355]=70, [6712]=1,
    [7209]=1, [7869]=70, [12033]=275, [13875]=175, [13918]=250,
    [16882]=1, [16883]=70, [16884]=175, [16885]=250, [29569]=300,
    [31952]=325, [43575]=350, [43622]=375, [43624]=400, [45986]=400,
}

local function ItemID(link)
    return link and tonumber(string.match(link, "item:(%d+)"))
end

local function ProfessionSkill(name)
    if not GetNumSkillLines or not GetSkillLineInfo then return nil end
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, rank = GetSkillLineInfo(i)
        if not isHeader and skillName == name then return rank or 0 end
    end
    return 0
end

local function SpellKnown(id)
    if IsSpellKnown and IsSpellKnown(id) then return true end
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
    if not GetSpellName then return false end
    local name = GetSpellInfo(id)
    if not name then return false end
    local index = 1
    while true do
        local spellName = GetSpellName(index, BOOKTYPE_SPELL)
        if not spellName then return false end
        if spellName == name then return true end
        index = index + 1
    end
end

-- Read the client's own disenchant lines, including custom non-equipment items.
-- No item-level formula can supply reliable requirements for this server.
local function CleanTooltipText(text)
    if type(text) ~= "string" then return "" end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$"))
end
local function FormatPattern(format)
    if type(format) ~= "string" then return end
    local pattern = format:gsub("%%s", "\001"):gsub("%%d", "\002")
    pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    return "^" .. pattern:gsub("\001", "(.-)"):gsub("\002", "(%%d+)") .. "$"
end
local function ParseDisenchantLines(lines)
    local eligible, required, profession, red
    for _, line in ipairs(lines) do
        local text = CleanTooltipText(line.text)
        if text ~= "" then
            if text == CleanTooltipText(ITEM_DISENCHANT_NOT_DISENCHANTABLE) or
                text:lower() == "cannot be disenchanted" then
                return false, nil, nil, false, "tooltip"
            end
            if text == CleanTooltipText(ITEM_DISENCHANT_ANY_SKILL) then eligible, required = true, 0
            elseif text:lower() == "disenchantable" then eligible = true end
            -- Warcraft Forever uses this description on disenchantable quest goods.
            -- Match the observed sentence, not a generic mention of Disenchanting.
            local description = text:lower():gsub('^"', ''):gsub('"$', ''):gsub("%s+", " ")
            if description == "the faint magic within can be extracted with the disenchanting skill." then
                eligible = true
            end
            local pattern = FormatPattern(ITEM_DISENCHANT_MIN_SKILL)
            local name, rank
            if pattern then name, rank = text:match(pattern) end
            if not rank then name, rank = text:match("^Disenchanting requires (.-) %((%d+)%)%.?$") end
            if rank then
                eligible, required, profession = true, tonumber(rank), name
                red = line.red == true
            end
        end
    end
    return eligible, required, profession, red, eligible and "tooltip" or "unknown"
end
local scanTooltip
local function DisenchantLines(bag, slot)
    local lines = {}
    if bag == nil or slot == nil then return lines end
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local data = C_TooltipInfo.GetBagItem(bag, slot)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                for _, side in ipairs({"left", "right"}) do
                    local color = line[side .. "Color"]
                    local r, g, b
                    if color and color.GetRGB then r, g, b = color:GetRGB()
                    elseif color then r, g, b = color.r, color.g, color.b end
                    lines[#lines+1] = {text=line[side .. "Text"], red=r and r > 0.8 and g < 0.3 and b < 0.3}
                end
            end
            return lines
        end
    end
    -- Older Classic clients expose the same data through a hidden tooltip.
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "QuickProspectScanTooltip", UIParent, "GameTooltipTemplate")
    end
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTooltip:ClearLines()
    scanTooltip:SetBagItem(bag, slot)
    for i = 1, scanTooltip:NumLines() do
        for _, side in ipairs({"Left", "Right"}) do
            local font = _G["QuickProspectScanTooltipText" .. side .. i]
            if font then
                local r, g, b = font:GetTextColor()
                lines[#lines+1] = {text=font:GetText(), red=r > 0.8 and g < 0.3 and b < 0.3}
            end
        end
    end
    scanTooltip:Hide()
    return lines
end
local deCache = {}
local function ClearDisenchantCache() deCache = {} end
local function DisenchantDetails(link, bag, slot)
    local key = tostring(bag) .. ":" .. tostring(slot)
    local now = GetTime and GetTime() or 0
    local cached = deCache[key]
    if cached and cached.link == link and now < cached.expires then return cached end
    local lines = DisenchantLines(bag, slot)
    local eligible, required, profession, red, source = ParseDisenchantLines(lines)
    local rank
    if required then
        rank = ProfessionSkill(profession or "Enchanting")
        if GetProfessions and GetProfessionInfo then
            for _, index in pairs({GetProfessions()}) do
                local _, _, skill, _, _, _, skillLine = GetProfessionInfo(index)
                if skillLine == 333 then rank = skill; break end
            end
        end
    end
    local info = {link=link, expires=now+0.5, eligible=eligible, required=required,
        rank=rank, blocked=red or (required and rank and rank < required) or false,
        source=source, lines=lines}
    deCache[key] = info
    return info
end

local function Classification(link, count, bag, slot)
    local id = ItemID(link)
    if not id then return end

    local requirement = ORES[id]
    if requirement and SpellKnown(SPELL_PROSPECT) then
        if (count or 0) < 5 then return end
        if (ProfessionSkill("Jewelcrafting") or requirement) < requirement then
            return "Prospecting", SPELL_PROSPECT, COLOR_TOO_HIGH, true
        end
        return "Prospecting", SPELL_PROSPECT, COLOR_PROSPECT
    end

    requirement = HERBS[id]
    if requirement and SpellKnown(SPELL_MILL) then
        if (count or 0) < 5 then return end
        if (ProfessionSkill("Inscription") or requirement) < requirement then return end
        return "Milling", SPELL_MILL, COLOR_MILL
    end

    requirement = LOCKBOXES[id]
    if requirement and SpellKnown(SPELL_PICK_LOCK) then
        if (ProfessionSkill("Lockpicking") or requirement) < requirement then
            return "Lockpicking", SPELL_PICK_LOCK, COLOR_TOO_HIGH, true
        end
        return "Lockpicking", SPELL_PICK_LOCK, COLOR_LOCKPICK
    end

    if SpellKnown(SPELL_DISENCHANT) then
        local detail = DisenchantDetails(link, bag, slot)
        if detail.eligible == false then return end
        if detail.eligible == true then
            return "Disenchanting", SPELL_DISENCHANT, detail.blocked and COLOR_TOO_HIGH or COLOR_DISENCHANT, detail.blocked, detail
        end
        local _, _, quality, _, _, itemType, _, _, equipLoc, _, _, classID = GetItemInfo(link)
        if quality and quality >= 2 and quality <= 4 and equipLoc and equipLoc ~= "" and
           (classID == 4 or classID == 2 or itemType == "Armor" or itemType == "Weapon") then
            return "Disenchanting", SPELL_DISENCHANT, COLOR_DISENCHANT, false, detail
        end
    end
end


local frame = CreateFrame("Frame")
local hasShine = AutoCastShine_AutoCastStart and AutoCastShine_AutoCastStop
local button = CreateFrame("Button", "QuickProspectSecureButton", UIParent,
    "SecureActionButtonTemplate" .. (hasShine and ",AutoCastShineTemplate" or ""))
button:Hide()
button:SetFrameStrata("TOOLTIP")
button:SetFrameLevel(100)
button:RegisterForClicks("AnyDown", "AnyUp")
button:EnableMouse(true)
button:SetAttribute("checkselfcast", false)
button:SetAttribute("checkfocuscast", false)
-- Built-in visibility handling does not compile restricted Lua snippets.
-- 'ready' deliberately does nothing: only a validated hovered item may show us.
RegisterStateDriver(button, "visibility", "[combat] hide; [mod:alt] ready; hide")
local glow = button:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetBlendMode("ADD")
glow:SetPoint("CENTER")
glow:SetDrawLayer("OVERLAY", 7)
if hasShine then
    glow:Hide()
    for _, sparkle in pairs(button.sparkles or {}) do
        sparkle:SetWidth(sparkle:GetWidth() * 3)
        sparkle:SetHeight(sparkle:GetHeight() * 3)
    end
end
button:HookScript("OnHide", function(self)
    if hasShine then AutoCastShine_AutoCastStop(self) end
end)
local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8f63ffQuickProspect|r " .. text)
end
local function BagInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.hyperlink, info.stackCount, info.isLocked end
    elseif GetContainerItemInfo then
        local _, count, locked = GetContainerItemInfo(bag, slot)
        return GetContainerItemLink(bag, slot), count, locked
    end
end
local tooltipOwner, tooltipBag, tooltipSlot
if GameTooltip and GameTooltip.SetBagItem and hooksecurefunc then
    hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
        tooltipOwner, tooltipBag, tooltipSlot = self:GetOwner(), bag, slot
    end)
end
local function Slot(owner)
    if not owner then return end
    if owner == tooltipOwner then return tooltipBag, tooltipSlot end
    if owner.GetSlotAndBagID then
        local slot, bag = owner:GetSlotAndBagID()
        return bag, slot
    end
    if owner.GetBagID and owner.GetID then return owner:GetBagID(), owner:GetID() end
    -- Restrict the fallback to Blizzard container buttons, never equipment slots.
    if owner.GetName and (owner:GetName() or ""):match("^ContainerFrame%d+Item%d+$") then
        return owner:GetParent():GetID(), owner:GetID()
    end
end
local function FindOwner(candidate)
    for _ = 1, 5 do
        if not candidate or candidate == UIParent or candidate == button then return end
        local bag, slot = Slot(candidate)
        if type(bag) == "number" and type(slot) == "number" then return candidate, bag, slot end
        candidate = candidate.GetParent and candidate:GetParent()
    end
end
local lastDiagnostic
local function Diagnose(text)
    if QuickProspectDB and QuickProspectDB.debug and text ~= lastDiagnostic then
        Print(text)
        lastDiagnostic = text
    end
end
local target
local function Hide()
    if InCombatLockdown() then return end
    button:Hide()
    target = nil
end
button:HookScript("OnLeave", Hide)
local function Update()
    if InCombatLockdown() then return end
    if not IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown() then Hide(); return end
    local owner, bag, slot
    if button:IsShown() and button:IsMouseOver() then
        owner, bag, slot = FindOwner(target)
    else
        if GetMouseFoci then
            for _, focus in ipairs(GetMouseFoci()) do
                owner, bag, slot = FindOwner(focus)
                if owner then break end
            end
        elseif GetMouseFocus then
            owner, bag, slot = FindOwner(GetMouseFocus())
        end
        if not owner and GameTooltip and GameTooltip:IsShown() then
            local candidate = GameTooltip:GetOwner()
            if candidate and candidate.IsMouseOver and candidate:IsMouseOver() then
                owner, bag, slot = FindOwner(candidate)
            end
        end
    end
    if not owner or not owner:IsVisible() then Diagnose("Alt hover: no bag item detected."); Hide(); return end
    if type(bag) ~= "number" or type(slot) ~= "number" or bag < 0 or
        bag > (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) or slot < 1 then Hide(); return end
    local link, count, locked = BagInfo(bag, slot)
    if locked then Hide(); return end
    local action, spellID, color, blocked, detail = Classification(link, count, bag, slot)
    local _, _, quality, _, _, itemType, _, _, equipLoc, _, _, classID = GetItemInfo(link or 0)
    Diagnose(string.format("Alt hover: bag %s slot %s, item %s, count %s, Disenchant known %s, quality %s, type %s/%s, equip %s, action %s.",
        tostring(bag), tostring(slot), tostring(ItemID(link)), tostring(count),
        tostring(SpellKnown(SPELL_DISENCHANT)), tostring(quality), tostring(itemType), tostring(classID),
        tostring(equipLoc), tostring(action or "none")))
    if QuickProspectDB and QuickProspectDB.debug and not action and SpellKnown(SPELL_DISENCHANT) then
        local info = DisenchantDetails(link, bag, slot)
        local text = {}
        for _, line in ipairs(info.lines) do
            if line.text and line.text ~= "" then text[#text+1] = CleanTooltipText(line.text) end
        end
        -- Kept separate from hover diagnostics to avoid alternating messages each tick.
        local report = table.concat(text, " / ")
        if button.lastTooltipReport ~= report then
            Print("Disenchant tooltip: " .. (report ~= "" and report or "no tooltip data"))
            button.lastTooltipReport = report
        end
    end
    if not action then Hide(); return end
    target = owner
    button:ClearAllPoints()
    button:SetAllPoints(owner)
    glow:SetSize(owner:GetWidth() * 1.75, owner:GetHeight() * 1.75)
    glow:SetVertexColor(color[1], color[2], color[3])
    if blocked then button:SetAttribute("alt-type1", nil)
    else button:SetAttribute("alt-type1", "spell") end
    button:SetAttribute("spell", spellID)
    button:SetAttribute("target-bag", bag)
    button:SetAttribute("target-slot", slot)
    button.action, button.blocked = action, blocked
    button.detail = detail
    button:Show()
    if hasShine then AutoCastShine_AutoCastStart(button, color[1], color[2], color[3])
    else glow:Show() end
end
button:HookScript("OnEnter", function(self)
    if not GameTooltip or not GameTooltip.SetOwner then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(self:GetAttribute("target-bag"), self:GetAttribute("target-slot"))
    if self.action == "Disenchanting" then
        local detail = self.detail
        local requirement = detail and detail.required
        local text = requirement and ("QuickProspect: Requires Enchanting " .. requirement ..
            (detail.rank and (" (yours: " .. detail.rank .. ")") or "")) or
            "QuickProspect: Enchanting requirement not reported by client."
        GameTooltip:AddLine(text, self.blocked and 1 or 0.7, self.blocked and 0.1 or 0.5, self.blocked and 0.1 or 1, true)
        GameTooltip:Show()
    end
end)
button:HookScript("PostClick", function(self, mouse, down)
    if mouse ~= "LeftButton" or down then return end
    if self.blocked then Print("Your skill is too low for " .. self.action .. ".") end
    if QuickProspectDB and QuickProspectDB.debug then
        Print(string.format("%s: bag %s, slot %s, blocked %s.", tostring(self.action),
            tostring(self:GetAttribute("target-bag")), tostring(self:GetAttribute("target-slot")), tostring(self.blocked == true)))
    end
    Hide()
end)
local elapsedTime = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    elapsedTime = elapsedTime + elapsed
    if elapsedTime >= 0.05 then elapsedTime = 0; Update() end
end)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:SetScript("OnEvent", function(_, event)
    ClearDisenchantCache()
    if event == "PLAYER_LOGIN" then
        QuickProspectDB = QuickProspectDB or {}
        Print("1.1.4-forever loaded. Hold Alt and left-click a highlighted bag item. /qp for status.")
    end
    Hide()
end)
SLASH_QUICKPROSPECT1, SLASH_QUICKPROSPECT2 = "/quickprospect", "/qp"
SlashCmdList.QUICKPROSPECT = function(message)
    QuickProspectDB = QuickProspectDB or {}
    if (message or ""):lower():match("^debug") then
        QuickProspectDB.debug = not QuickProspectDB.debug
        Print("Debug " .. (QuickProspectDB.debug and "enabled." or "disabled."))
        return
    end
    local known = {}
    for _, entry in ipairs({{SPELL_PROSPECT,"Prospecting"},{SPELL_MILL,"Milling"},
        {SPELL_DISENCHANT,"Disenchanting"},{SPELL_PICK_LOCK,"Lockpicking"}}) do
        if SpellKnown(entry[1]) then known[#known+1] = entry[2] end
    end
    local version, build, _, interface = GetBuildInfo()
    Print(string.format("1.1.4-forever; client %s (%s), interface %s; %s. /qp debug toggles diagnostics.",
        version, build, interface, #known > 0 and table.concat(known, ", ") or "no processing spells learned"))
end
