
local API = DigamAddonLib.API;

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

function API.GetGuildInfo(unitid)
    return GetGuildInfo(unitid);
end;

function API.GetLootMethod()
    return C_PartyInfo.GetLootMethod();
end

function API.GetMouseButtonClicked()
    return GetMouseButtonClicked();
end;

function API.GetNumGroupMembers()
    return GetNumGroupMembers();
end;

function API.GetNumTrackingTypes()
    return C_Minimap.GetNumTrackingTypes();
end

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

function API.InCombatLockdown()
    return InCombatLockdown();
end;

function API.IsInInstance()
    local inInstance, instanceType = IsInInstance()
    
    -- Hvis Forever returnerer den boolske værdi 'true', konverterer vi det til tallet 1
    if inInstance == true then
        inInstance = 1
    end
    
    return inInstance, instanceType
end

function API.IsInRaid()
    return IsInRaid();
end;

-- 4. IsSpellInRange returns booleans (true/false) instead of 1/0.
function API.IsSpellInRange(buffName, unitid)
    return C_Spell.IsSpellInRange(buffName, unitid)
end

function API.RegisterAddonMessagePrefix(prefix)
    return C_ChatInfo.RegisterAddonMessagePrefix(prefix);
end;

function API.SendAddonMessage(addonPrefix, message, channel, target)
    C_ChatInfo.SendAddonMessage(addonPrefix, message, channel, target)
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

    if UnitAffectingCombat("player") then
        return nil;
    end;

    -- Directly request data by its sequential index within the filtered range
    local aura = C_UnitAuras.GetAuraDataByIndex(unitId, index, foreverFilter)
    if not aura then
        return nil
    end
    
    -- Return the exact 11 classic values your Era-core expects
    return 
        aura.name, 
        "", -- Rank does not exist in retail backend
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


--
--  Forever Only:
--

function API.Extract_Unit_Target(castGUID)
    local name = nil
    
    if UnitExists("mouseover") then
        name = GetUnitName("mouseover")
    elseif UnitExists("target") then
        name = GetUnitName("target")
    end
    
    -- Returns the string name or nil if empty/not found
    if name == "" then
        name = nil;
    end

    return name;
end



