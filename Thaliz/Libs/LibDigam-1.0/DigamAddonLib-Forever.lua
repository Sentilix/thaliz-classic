
local API = DigamAddonLib.API;

-- FIXED v1.0.0 FOREVER PROPER FILTER: Uses true underlying profession ID tracking maps to crush contamination
local PROFESSION_ID_MAP = {
    [171] = { name = "Alchemy",        isSecondary = false },
    [164] = { name = "Blacksmithing",  isSecondary = false },
    [333] = { name = "Enchanting",     isSecondary = false },
    [202] = { name = "Engineering",    isSecondary = false },
    [165] = { name = "Leatherworking", isSecondary = false },
    [197] = { name = "Tailoring",      isSecondary = false },
    [186] = { name = "Mining",         isSecondary = false },
    [182] = { name = "Herbalism",      isSecondary = false },
    [393] = { name = "Skinning",       isSecondary = false },
    -- SECONDARY ALIGNMENT TIERS
    [185] = { name = "Cooking",        isSecondary = true },
    [129] = { name = "First Aid",      isSecondary = true },
    [356] = { name = "Fishing",        isSecondary = true },
}


-- 1. CreateFrame requires BackdropTemplate in Forever if using :SetBackdrop()
function API.CreateFrame(frameType, frameName, parentFrame, inheritsFrame, id)
    -- Add BackdropTemplate if creating a Frame with a name/parent:
    if frameType == "Frame" and not inheritsFrame then
        inheritsFrame = "BackdropTemplate"
    end
    return CreateFrame(frameType, frameName, parentFrame, inheritsFrame, id);
end;

function API.GetAddOnMetadata(addonName, keyName)
    return C_AddOns.GetAddOnMetadata(addonName, keyName);
end;

-- Returns avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel()
function API.GetAverageItemLevel()
    return GetAverageItemLevel()
end;

function API.GetBuildInfo()
    return GetBuildInfo();
end;

-- Returns containerInfo = C_Container.GetContainerItemInfo(containerIndex, slotIndex)
function API.GetContainerItemInfo(containerIndex, slotIndex)
    return C_Container.GetContainerItemInfo(containerIndex, slotIndex)
end;

-- Returns itemLink = C_Container.GetContainerItemLink(containerIndex, slotIndex)
function API.GetContainerItemLink(containerIndex, slotIndex)
    return C_Container.GetContainerItemLink(containerIndex, slotIndex)
end;

-- Returns numSlots = C_Container.GetContainerNumSlots(containerIndex)
function API.GetContainerNumSlots(containerIndex)
    return C_Container.GetContainerNumSlots(containerIndex)
end;

-- Returns name, rank, maxRank = C_TradeSkillUI.GetRecipeProfessionInfo() equivalent variables
function API.GetCraftDisplaySkillLine()
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    if info then
        return info.professionName, info.professionRank, info.professionMaxRank
    end
    return nil, 0, 0
end;

-- Returns craftName, craftSubSpellName, craftType, numAvailable, isHeader, trainingPointCost, requiredLevel
function API.GetCraftInfo(index)
    local recipeID = C_TradeSkillUI.GetRecipeIDByIndex(index)
    if not recipeID then return nil end

    local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
    if info then
        local craftType = info.difficulty
        if info.isHeader then craftType = "header" end
        
        return info.name, "", craftType, info.numAvailable, info.isHeader, 0, 0
    end
    return nil
end;

function API.GetGuildInfo(unitid)
    return GetGuildInfo(unitid);
end;

--  Returns itemLink
function API.GetInventoryItemLink(unit, slotID)
    return GetInventoryItemLink(unit, slotID);
end;

-- Returns iconFileID = C_Item.GetItemIconByID(itemID)
function API.GetItemIconByID(itemID)
    return C_Item.GetItemIconByID(itemID)
end;

--  Returns itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, 
--  itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent, itemDescription
function API.GetItemInfo(item)
    return C_Item.GetItemInfo(item);
end;

--  Returns itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
function API.GetItemInfoInstant(item)
    return C_Item.GetItemInfoInstant(item);
end;

function API.GetLootMethod()
    return C_PartyInfo.GetLootMethod();
end

-- Returns copper = GetMoney()
function API.GetMoney()
    return GetMoney()
end;

function API.GetMouseButtonClicked()
    return GetMouseButtonClicked();
end;

function API.GetNumGroupMembers()
    return GetNumGroupMembers();
end;

-- Returns numSavedInstances = GetNumSavedInstances()
function API.GetNumSavedInstances()
    return GetNumSavedInstances()
end;

-- Returns numSkillLines = C_SkillInfo.GetNumSkillLines()
--  See the Profession emulation
--function API.GetNumSkillLines()
--    return C_SkillInfo.GetNumSkillLines()
--end;

-- Global high-performance points cache for the three talent tabs in Forever
local emulatedTalentPoints = { [1] = 0, [2] = 0, [3] = 0 }
local emulatedNumTalents = { [1] = 0, [2] = 0, [3] = 0 }

-- Private core function to parse modern C_Traits config maps into classic 3-tab buckets
local function PopulateForeverTalentCache()
    emulatedTalentPoints[1], emulatedTalentPoints[2], emulatedTalentPoints[3] = 0, 0, 0
    emulatedNumTalents[1], emulatedNumTalents[2], emulatedNumTalents[3] = 0, 0, 0

    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID()
    if not configID then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    local treeIDs = configInfo and configInfo.treeIDs
    local treeID = treeIDs and treeIDs[1]
    if not treeID then return end

    -- Extract all active node entries inside the structural class talent tree
    local nodes = C_Traits.GetTreeNodes(treeID)
    if not nodes then return end

    -- Map modern structural node elements directly to index 1, 2 and 3 tabs
    for _, nodeID in ipairs(nodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        if nodeInfo and nodeInfo.subTreeID then
            -- Blizzard's subTreeID structure naturally maps to sequential tab buckets (1, 2, 3)
            local tabIndex = nodeInfo.subTreeID
            if emulatedTalentPoints[tabIndex] then
                emulatedNumTalents[tabIndex] = emulatedNumTalents[tabIndex] + 1
                
                -- Check if the player has allocated points in this node
                local entryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
                if entryID then
                    local assignmentInfo = C_Traits.GetAssignmentInfo(configID, nodeID)
                    local ranksAllocated = assignmentInfo and assignmentInfo.ranksAllocated or 0
                    emulatedTalentPoints[tabIndex] = emulatedTalentPoints[tabIndex] + ranksAllocated
                end
            end
        end
    end
end

-- BEGIN EMULATED TALENT API: Returns numTabs = 3 (Matches Classic Era perfectly)
-- Static emulated storage container array counters
local emulatedTotalPoints = 0
local cacheIsPopulated = false

-- Private high-performance parser that rips true allocated ranks directly out of Blizzards active layout config
local function PopulateForeverTalentCache()
    emulatedTotalPoints = 0

    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID()
    if not configID then return end

    -- Fetch the universal trait tree mapping structure safely
    local specID = GetSpecialization and GetSpecialization()
    local specInfoID = specID and GetSpecializationInfo(specID)
    
    -- FIXED v1.0.0 NAMESPACE: Fallback directly onto the configuration info structure via C_Traits to block nil-pointer crashes
    local treeID = specInfoID and C_ClassTalents.GetTraitTreeForSpec(specInfoID)
    if not treeID then
        local configInfo = C_Traits.GetConfigInfo(configID)
        local treeIDs = configInfo and configInfo.treeIDs
        treeID = treeIDs and treeIDs[1]
    end
    
    if not treeID then return end

    local nodes = C_Traits.GetTreeNodes(treeID)
    if not nodes then return end

    -- Loop directly through every single node blueprint inside the active layout context
    for _, nodeID in ipairs(nodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        if nodeInfo and nodeInfo.isVisible then
            -- FIXED v1.0.0 FOREVER FIELD: Use activeRank instead of currentRank to accurately tally allocated points
            local ranks = nodeInfo.activeRank or 0
            if ranks > 0 then
                emulatedTotalPoints = emulatedTotalPoints + ranks
            end
        end
    end
    cacheIsPopulated = true
end

-- EMULATED API: Returns numTabs = 3 (Blocks silent crashes completely)
function API.GetNumTalentTabs(isInspect, isPet)
    PopulateForeverTalentCache()
    return 3
end

-- EMULATED API: We fake exactly 1 loop iteration per tab to make calculation super fast and elegant
function API.GetNumTalents(tabIndex)
    if not cacheIsPopulated then
        PopulateForeverTalentCache()
    end
    return 1
end

-- EMULATED API: Safely returns all 5 arguments across all tabs to prevent indexing crashes
function API.GetTalentInfo(tabIndex, talentIndex)
    if tabIndex == 1 and talentIndex == 1 then
        return "EmulatedTalent", nil, nil, nil, emulatedTotalPoints
    end
    return "DummyTalent", nil, nil, nil, 0
end
--  END EMULATED TALENT API


function API.GetNumTrackingTypes()
    return C_Minimap.GetNumTrackingTypes();
end

-- Returns numSkills = total amount of individual recipes available
function API.GetNumTradeSkills()
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    return recipeIDs and #recipeIDs or 0
end;

--  Forever returned values: localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName
function API.GetPlayerInfoByGUID(guid)
    return GetPlayerInfoByGUID(guid);
end;

function API.GetRaidRosterInfo(raidIndex)
    return GetRaidRosterInfo(raidIndex);
end;

function API.GetRealmName()
    return GetRealmName();
end;

-- Returns zoneText = GetRealZoneText()
function API.GetRealZoneText()
    return GetRealZoneText()
end;

-- Returns name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(index)
function API.GetSavedInstanceInfo(index)
    return GetSavedInstanceInfo(index)
end;

-- Era Return Signature: name, texture, count, quality, canLink, itemID, itemType, itemSubtype
function API.GetSendMailItem(index)
    local name, itemID, texture, count, quality = GetSendMailItem(index)
    
    if not name or not itemID then 
        return nil 
    end

    local itemType, itemSubtype
    if C_Item and C_Item.GetItemInfo then
        _, _, _, _, _, _, itemType, itemSubtype = C_Item.GetItemInfo(itemID)
    else
        -- Fallback safeguard in case local cache overrides apply
        _, _, _, _, _, _, itemType, itemSubtype = GetItemInfo(itemID)
    end

    return name, texture, count, quality, nil, itemID, itemType, itemSubtype
end


function API.GetSendMailItemLink(index)
    return GetSendMailItemLink(index)
end


--  BEGIN Profession emulation
local function GetActiveProfessionsCache()
    local list = {}
    
    -- Step 1: Core dynamic scan for learned Primary Professions
    if _G.GetProfessions then
        local p1, p2 = _G.GetProfessions()
        local primaries = { p1, p2 }
        
        for _, profIndex in ipairs(primaries) do
            if profIndex and profIndex > 0 then
                local name, _, skillLevel, maxSkillLevel, _, _, skillLineID = _G.GetProfessionInfo(profIndex)
                
                local mapData = skillLineID and PROFESSION_ID_MAP[skillLineID]
                local finalName = mapData and mapData.name or name
                
                if finalName and skillLevel and skillLevel > 0 then
                    table.insert(list, {
                        name = finalName,
                        isHeader = false,
                        skillRank = skillLevel,
                        skillMax = maxSkillLevel or 0,
                        id = skillLineID or profIndex
                    })
                end
            end
        end
    end

    -- Step 2: Cataclysm Native Secondary Profession Injection via immutable Skill Line IDs
    for id, meta in pairs(PROFESSION_ID_MAP) do
        if meta.isSecondary then
            -- FIXED v1.0.0 CATA ENGINE LINK: Pull info directly from the modern sync SkillLine structural ledger
            if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(id)
                if info and info.skillLevel and info.skillLevel > 0 then
                    table.insert(list, {
                        name = meta.name,
                        isHeader = false,
                        skillRank = info.skillLevel,
                        skillMax = info.maxSkillLevel or 0,
                        id = id
                    })
                end
            end
        end
    end

    return list
end

function API.GetNumSkillLines()
    local cache = GetActiveProfessionsCache()
    return cache and #cache or 0
end

function API.GetSkillLineInfo(index)
    local profList = GetActiveProfessionsCache()
    if not profList or not profList[index] then return nil end
    local profData = profList[index]
    
    return profData.name, profData.isHeader, false, profData.skillRank, 0, 0, profData.skillMax, false, 0, 0, 1, profData.id, false
end

function API.GetTradeSkillLine()
    local currentProfInfo = C_TradeSkillUI.GetBaseProfessionInfo()
    if currentProfInfo and currentProfInfo.professionName then
        return currentProfInfo.professionName
    end
    return nil
end

function API.GetNumTradeSkills()
    local recipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs()
    return recipeIDs and #recipeIDs or 0
end
--  END Profession emulation

-- Returns spellName, spellSubName = C_SpellBook.GetSpellBookItemName() equivalent variables
function API.GetSpellBookItemName(index, bookType)
    local bank = (bookType == "pet") and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
    return C_SpellBook.GetSpellBookItemName(index, bank)
end;

function API.GetSpellCooldown(spellIdentifier)
    local info = C_Spell.GetSpellCooldown(spellIdentifier)
    if info then
        return info.startTime, info.duration, info.isEnabled, info.modRate
    end
    return 0, 0, false, 1;
end

function API.GetSpellIDForSpellIdentifier(spellIdentifier)
    return C_Spell.GetSpellIDForSpellIdentifier(spellIdentifier);
end;

-- 2. C_Spell.GetSpellInfo returns a table in Forever. Extract it to the old Era format:
function API.GetSpellInfo(spellIdentifier)
    if spellIdentifier then
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)

        if spellInfo then
            return 
                spellInfo.name, 
                nil, -- rank does not exist in Forever backend
                spellInfo.iconID, 
                spellInfo.castTime, 
                spellInfo.minRange, 
                spellInfo.maxRange, 
                spellInfo.spellID, 
                spellInfo.originalIconID
        end
    end
    return nil    
end

-- Emulate the old layout where icon is 3rd and spellID is 7th return value
function API.GetSpellName(spellIdentifier)
    if spellIdentifier then
        -- Fetch the new unified spell data table from the modern backend
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
        if spellInfo then
            -- Returns: name(1), rank(2), iconID(3), castTime(4), minRange(5), maxRange(6), spellID(7)
            return 
                spellInfo.name, 
                nil, 
                spellInfo.iconID, 
                spellInfo.castTime, 
                spellInfo.minRange, 
                spellInfo.maxRange, 
                spellInfo.spellID
        end
    end
    return nil
end;

--  Returns name, iconTexture, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabIndex, talentIndex [, isInspect, isPet, groupIndex])
--See the emulated talent API!
--function API.GetTalentInfo(tabIndex, talentIndex, isInspect, isPet, groupIndex)
--    return GetTalentInfo(tabIndex, talentIndex, isInspect, isPet, groupIndex);
--end;

function API.GetTime()
    return GetTime();
end;

function API.GetTrackingInfo(index)
    return C_Minimap.GetTrackingInfo(index);
end;

-- 3. GetTrackingTexture() - use C_Minimap in Forever:
function API.GetTrackingTexture()
    local count = C_Minimap.GetNumTrackingTypes()
    for i = 1, count do
        local info = C_Minimap.GetTrackingInfo(i)
        if info and info.active then
            return info.texture -- Returns ikonet for the active tracking
        end
    end
    return nil
end;

-- Returns name, difficulty, numAvailable, isHeader, isExpanded, id
--  NOTE: THIS IS NOT COMPATIBLE WITH ERA, USE GetTradeSkillInfo_Era(index, professionName), which
--  has an added professionName parameter for filtering.
function API.GetTradeSkillInfo_Era(index, professionName)
    return API.GetTradeSkillInfo(index)
end

-- Returns name, difficulty, numAvailable, isHeader, isExpanded, id
function API.GetTradeSkillInfo_Era(index, professionName)
    local recipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs()
    if not recipeIDs or not recipeIDs[index] then return nil end
      
    local recipeID = recipeIDs[index]
    local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
    if info then
        local currentProfInfo = C_TradeSkillUI.GetProfessionInfoByRecipeID(info.recipeID)
        local activeProfessionInfo = PROFESSION_ID_MAP[currentProfInfo.parentProfessionID];
        local activeProfessionName = activeProfessionInfo and activeProfessionInfo.Name;

        local difficulty = info.difficulty or "trivial"
        local isHeader = info.isHeader
        
        if not info.learned or not activeProfessionName then
            isHeader = true
            difficulty = "header"
        elseif professionName and activeProfessionName ~= professionName then
            -- If the scraper loops "Cooking", but the UI engine is still processing "Alchemy" -> Evict instantly!
            isHeader = true
            difficulty = "header"
        elseif info.isHeader then 
            difficulty = "header" 
        end
        
        return info.name, difficulty, info.numAvailable, isHeader, info.isExpanded, recipeID
    end
    return nil
end

-- Returns tradeskillName, currentLevel, maxLevel, skillLineModifier = C_TradeSkillUI.GetBaseProfessionInfo() equivalent variables
function API.GetTradeSkillLine()
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    if info then
        return info.professionName, info.professionRank, info.professionMaxRank, 0
    end
    return "UNKNOWN", 0, 0, 0
end;

-- Returns exhaustion = GetXPExhaustion()
function API.GetXPExhaustion()
    return GetXPExhaustion()
end;

function API.InCombatLockdown()
    return InCombatLockdown();
end;

function API.IsInGroup()
    return IsInGroup();
end;

function API.IsInInstance()
    return IsInInstance();
end

function API.IsInRaid()
    return IsInRaid();
end;

-- Returns isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
function API.IsQuestFlaggedCompleted(questID)
    return C_QuestLog.IsQuestFlaggedCompleted(questID)
end;

-- Returns resting = IsResting()
function API.IsResting()
    return IsResting()
end;

-- 4. IsSpellInRange returns booleans (true/false) instead of 1/0.
function API.IsSpellInRange(buffName, unitid)
    return C_Spell.IsSpellInRange(buffName, unitid)
end

function API.PlaySound(soundKitID, channel, forceMuteIfSessionMaxed, allowMultiple)
    return PlaySound(soundKitID, channel, forceMuteIfSessionMaxed, allowMultiple);
end;

function API.RegisterAddonMessagePrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and prefix then
        return C_ChatInfo.RegisterAddonMessagePrefix(prefix);
    end
end;

function API.RequestRaidInfo()
    return RequestRaidInfo();
end;

function API.SendAddonMessage(addonPrefix, message, channel, target)
    C_ChatInfo.SendAddonMessage(addonPrefix, message, channel, target)
end;

function API.SetPortraitTexture(textureObject, unitToken, disableMasking)
    return SetPortraitTexture(textureObject, unitToken, disableMasking);
end;

function API.SendChatMessage(message, chatType, languageID, target)
    SendChatMessage(message, chatType, languageID, target)
end;

function API.UnitAffectingCombat(unitId)
    return UnitAffectingCombat(unitId);
end;

function API.UnitBuff(unitId, index, filter)
    -- Fallback to "HELPFUL" if no filter is supplied by the core
    local foreverFilter = "HELPFUL"
    if filter and filter ~= "" then
        -- Ensure "HELPFUL" is present unless the core explicitly requests debuffs ("HARMFUL")
        if not string.find(filter, "HELPFUL") and not string.find(filter, "HARMFUL") then
            foreverFilter = "HELPFUL|" .. filter
        else
            foreverFilter = filter
        end
    end

    -- Wrap the API call in a pcall to catch "secret while tainted" errors gracefully
    local success, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unitId, index, foreverFilter)
    if not success or not aura then
        return nil
    end
    
    -- Return the exact 10 classic values your Era-core expects
    --  name, icon, count, dispelType, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId = UnitBuff("unitId", index [, "filter"])
    return 
        aura.name, 
        aura.icon, 
        aura.applications, 
        aura.dispelType, 
        aura.duration, 
        aura.expirationTime, 
        aura.sourceUnit, 
        aura.isStealable, 
        false, -- nameplateShowPersonal
        aura.spellId
end;

function API.UnitClass(unitId)
    return UnitClass(unitId);
end;

function API.UnitCreatureFamily(unitId)
    return UnitCreatureFamily(unitId);
end;

function API.UnitFactionGroup(unitId)
    return UnitFactionGroup(unitId);
end;

function API.UnitGUID(unitId)
    return UnitGUID(unitId);
end;

function API.UnitHasIncomingResurrection(unitid)
    return UnitHasIncomingResurrection(unitid)
end;

function API.UnitIsConnected(unitId)
    return UnitIsConnected(unitId);
end;

function API.UnitIsDead(unitId)
    return UnitIsDead(unitId);
end;

function API.UnitIsDeadOrGhost(unitId)
    return UnitIsDeadOrGhost(unitId);
end;

function API.UnitIsGroupAssistant(unitId)
    return UnitIsGroupAssistant(unitId);
end;

function API.UnitIsGroupLeader(unitId)
    return UnitIsGroupLeader(unitId);
end;

function API.UnitIsVisible(unitId)
    return UnitIsVisible(unitId);
end;

--  Returns level
function API.UnitLevel(unit)
    return UnitLevel(unit);
end;

function API.UnitName(unitId)
    return UnitName(unitId)
end;

function API.UnitRace(unitid)
    local localizedRaceName, englishRaceName, raceID = UnitRace(unitid)
    
    if not localizedRaceName then
        localizedRaceName, englishRaceName = "Unknown", "Unknown"
    end
    
    return localizedRaceName, englishRaceName, raceID
end

function API.UnitSex(unitid)
    local sex = UnitSex(unitid)
    return sex or 1
end

-- Returns currentXP = UnitXP(unit)
function API.UnitXP(unit)
    return UnitXP(unit)
end;

-- Returns maxXP = UnitXPMax(unit)
function API.UnitXPMax(unit)
    return UnitXPMax(unit)
end;



--
--  UNIT_SPELLCAST_* functions:
--

--[[
Convert output from UNIT_SPELLCAST_START event in Forever to
the format it ws in Era.
--]]

--  Forever return values: unitCaster, unitTarget, castGUID, spellID, castBarID
function API.On_UNIT_SPELLCAST_SENT(...)
    local unitCaster, _,spellID, lineID = ...
    return unitCaster, nil,spellID, lineID;
end;

--  Forever return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_START(...)
    return ...;
end

--  Forever return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_STOP(...)
    return ...;
end

--  Forever return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_SUCCEEDED(...)
    return ...;
end

--  Forever return values: unitCaster, castGUID, spellID, reason
--  Note the extra Reason field.
function API.Extract_UNIT_SPELLCAST_FAILED(...)
    return ...;
end

--  Forever payload: unitTarget, isIncoming
--  Era return values: unitTarget
function API.Extract_INCOMING_RESURRECT_CHANGED(...)
    return ...;
end




function API.Extract_Unit_Target()
    local name = nil
    
    if UnitExists("mouseover") then
        name = GetUnitName("mouseover")
    elseif UnitExists("target") then
        name = GetUnitName("target")
    end
    
    if name == "" then
        name = nil;
    end

    return name;
end



