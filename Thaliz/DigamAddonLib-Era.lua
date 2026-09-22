
local API = DigamAddonLib.API;

function API.CreateFrame(frameType, frameName, parentFrame, inheritsFrame, id)
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
end;

function API.GetMouseButtonClicked()
    return GetMouseButtonClicked();
end;

function API.GetNumGroupMembers()
    return GetNumGroupMembers();
end;

function API.GetNumTrackingTypes()
    return C_Minimap.GetNumTrackingTypes();
end

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

function API.GetTime()
    return GetTime();
end;

function API.GetTrackingInfo(index)
    return C_Minimap.GetTrackingInfo(index);
end;

function API.GetTrackingTexture()
    return GetTrackingTexture();
end;

function API.InCombatLockdown()
    return InCombatLockdown();
end;

function API.IsInInstance()
    return IsInInstance();
end;

function API.IsInRaid()
    return IsInRaid();
end;

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

function API.UnitName(unitId)
    return UnitName(unitId);
end;

function API.UnitRace(unitid)
    return UnitRace(unitid);
end;

function API.UnitSex(unitid)
    return UnitSex(unitid);
end;



--
--  Helpers:
--

--  Return PlayerName inclusive realm; aka full unique name.
function API.FullUnitName(unitId)
    local playername, realmname = API.UnitName(unitId);

    if playername then
        if not realmname or realmname == "" then
            realmname = GetRealmName();
        end;

        playername = playername ..'-'.. (realmname or '');    
    end;

    return playername;
end;

--  Return PlayerName esclusive realm; aka short but not unique name.
function API.ShortUnitName(unitId)
    local playername = API.UnitName(unitId);
    return playername;
end;



