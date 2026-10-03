
local API = DigamAddonLib.API;

function API.CreateFrame(frameType, frameName, parentFrame, inheritsFrame, id)
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

-- Returns name, rank, maxRank = GetCraftDisplaySkillLine()
function API.GetCraftDisplaySkillLine()
    return GetCraftDisplaySkillLine()
end;

-- Returns craftName, craftSubSpellName, craftType, numAvailable, isHeader, trainingPointCost, requiredLevel = GetCraftInfo(index)
function API.GetCraftInfo(index)
    return GetCraftInfo(index)
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
    return GetItemInfo(item);
end;

--  Returns itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
function API.GetItemInfoInstant(item)
    return GetItemInfoInstant(item);
end;

function API.GetLootMethod()
    return C_PartyInfo.GetLootMethod();
end;

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

-- Returns numSkillLines = GetNumSkillLines()
function API.GetNumSkillLines()
    return GetNumSkillLines()
end;

--  Returns numTabs
function API.GetNumTalentTabs(isInspect, isPet)
    return GetNumTalentTabs(isInspect, isPet);
end;

function API.GetNumTrackingTypes()
    return C_Minimap.GetNumTrackingTypes();
end

-- Returns numSkills = GetNumTradeSkills()
function API.GetNumTradeSkills()
    return GetNumTradeSkills()
end;

--  Era returned values: localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName
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

--  Returns name, itemID, texture, count, quality
function API.GetSendMailItem(index)
    return GetSendMailItem(index);
end;

--  Returns itemLink
function API.GetSendMailItemLink(index)
    return GetSendMailItemLink(index);
end;

-- Returns name, isHeader, isExpanded, skillRank, numSteps, skillModifier, maxRank, isAbandonable, stepCost, rankCost, minLevel, skillLineID, canEnhance = GetSkillLineInfo(index)
function API.GetSkillLineInfo(index)
    return GetSkillLineInfo(index)
end;

-- Returns spellName, spellSubName = GetSpellBookItemName(index, bookType)
function API.GetSpellBookItemName(index, bookType)
    return GetSpellBookItemName(index, bookType)
end;

function API.GetSpellCooldown(spellIdentifier)
    local info = C_Spell.GetSpellCooldown(spellIdentifier)
    
    if info then
        return info.startTime, info.duration, info.isEnabled, info.modRate
    end
    
    -- nil fallback:
    return 0, 0, false, 1;
end

function API.GetSpellIDForSpellIdentifier(spellIdentifier)
    return C_Spell.GetSpellIDForSpellIdentifier(spellIdentifier);
end;

function API.GetSpellInfo(spellIdentifier)
    if spellIdentifier then
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)

        if spellInfo then
            return 
                spellInfo.name, 
                nil,
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

function API.GetSpellName(spellId)
   return C_Spell.GetSpellName(spellId);
end;

--  Returns name, iconTexture, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabIndex, talentIndex [, isInspect, isPet, groupIndex])
function API.GetTalentInfo(tabIndex, talentIndex, isInspect, isPet, groupIndex)
    return GetTalentInfo(tabIndex, talentIndex, isInspect, isPet, groupIndex);
end;

function API.GetTime()
    return GetTime();
end;

function API.GetTrackingInfo(index)
    return C_Minimap.GetTrackingInfo(index);
end;

function API.GetTrackingTexture()
    return GetTrackingTexture();
end;

-- Returns name, difficulty, numAvailable, isHeader, isExpanded, id = GetTradeSkillInfo(index)
function API.GetTradeSkillInfo(index)
    return GetTradeSkillInfo(index)
end;

--  Same as GetTradeSkillInfo but supports professionName (for Forever - Era just skips it)
function API.GetTradeSkillInfo_Era(index, professionName)
    return API.GetTradeSkillInfo(index)
end

-- Returns tradeskillName, currentLevel, maxLevel, skillLineModifier = GetTradeSkillLine()
function API.GetTradeSkillLine()
    return GetTradeSkillLine()
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
end;

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

function API.SendChatMessage(message, chatType, languageID, target)
    C_ChatInfo.SendChatMessage(message, chatType, languageID, target)
end;

function API.SetPortraitTexture(textureObject, unitToken, disableMasking)
    return SetPortraitTexture(textureObject, unitToken, disableMasking);
end;

function API.UnitAffectingCombat(unitId)
    return UnitAffectingCombat(unitId);
end;

function API.UnitBuff(unitId, index, filter)
    return UnitBuff(unitId, index, filter);
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

function API.UnitIsVisible(unitid)
    return UnitIsVisible(unitid);
end;

--  Returns level
function API.UnitLevel(unit)
    return UnitLevel(unit);
end;

function API.UnitName(unitId)
    return UnitName(unitId);
end;

function API.UnitRace(unitid)
    return UnitRace(unitid);
end;

function API.UnitSex(unitid)
    return UnitSex(unitid);
end;

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

-- Era return values: unitCaster, unitTarget, castGUID, spellID
function API.On_UNIT_SPELLCAST_SENT(...)
    return ...;
end

--  Era return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_START(...)
    return ...;
end

--  Era return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_STOP(...)
    return ...;
end;

--  Era return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_SUCCEEDED(...)
    return ...;
end;

--  Era return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_FAILED(...)
    return ...;
end;

--  Era return values: unitTarget
function API.Extract_INCOMING_RESURRECT_CHANGED(...)
    return ...;
end;



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
