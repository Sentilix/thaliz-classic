--[[
--	Digam Addon Library
--	-------------------
--	Author: Mimma
--	File:   DigamAddonLib.lua
--	Desc:	Addon helper classes
--
--	First attempt to isolate common functionality into a separate file for 
--	easy reuse in other addons.
--]]


local DIGAM_IsDebugBuild					= false;
local DIGAM_BuildVersion					= 10.105;

local DIGAM_COLOR_BEGIN						= "|c80";
local DIGAM_CHAT_END						= "|r";
local DIGAM_DEFAULT_ColorNormal				= "40A0F8"
local DIGAM_DEFAULT_ColorHot				= "B0F0F0"

local RAID_CHANNEL							= "RAID"
local PARTY_CHANNEL							= "PARTY"
local YELL_CHANNEL							= "YELL"
local SAY_CHANNEL							= "SAY"
local WARN_CHANNEL							= "RAID_WARNING"
local GUILD_CHANNEL							= "GUILD"
local WHISPER_CHANNEL						= "WHISPER"

DIGAM_CHANNEL_RAID							= { ["id"] = "r", ["mask"] = 0x0001, ["name"] = "Raid", ["channel"] = "RAID", };
DIGAM_CHANNEL_RAIDWARNING					= { ["id"] ="rw", ["mask"] = 0x0002, ["name"] = "Raid warning", ["channel"] = "RAID_WARNING", };
DIGAM_CHANNEL_PARTY							= { ["id"] = "p", ["mask"] = 0x0004, ["name"] = "Party", ["channel"] = "PARTY", };
DIGAM_CHANNEL_CUSTOM						= { ["id"] = "?", ["mask"] = 0x0008, ["name"] = "(Custom)", ["channel"] = "CUSTOM", };



DigamAddonLib = CreateFrame("Frame"); 
DigamAddonLib.Locales = { };
DigamAddonLib.API = { };

local _isForeverEngine = false;


--[[
Define a Locale like en_US or fr_FR
Returns the locale table, ready to add translations.
--]]
function DigamAddonLib:CreateLocale(languageCode)
	DigamAddonLib.Locales[languageCode] = { };
	return DigamAddonLib.Locales[languageCode];
end;

--	Deprecated since 10.100, use CreateLocale(languageCode) instead
function DigamAddonLib:createLocale(languageCode)
	DigamAddonLib.Locales[languageCode] = { };
	return DigamAddonLib.Locales[languageCode];
end;

--[[
Translate a text.
Input: text key (usually the english text)
Returns thetranslated text or defaultText if no translation is found.
--]]
function DigamAddonLib:XL(defaultText)
	local locale = self.Locales[GetLocale()];
	if locale then
		local text = locale[defaultText];
		if text and type(text) == "string" then
			return text;
		end;
	end;

	return defaultText;
end;


--[[
Create a new instance of this addon.
--]]
function DigamAddonLib:New(addonSettings)
	local _addonName = addonSettings["ADDONNAME"] or "Unnamed";
	local _addonShortName = addonSettings["SHORTNAME"] or _addonName;
	local _addonPrefix = addonSettings["PREFIX"] or _addonShortName;
	local _addonVersion = self.API.GetAddOnMetadata(_addonName, "Version") or 0;

	local clientBuildVersion, clientBuildNumber, clientBuildDate, clientInterfaceVersion = GetBuildInfo();
	local _major, _minor, _build = string.match(clientBuildVersion, "(%d+)%.(%d+)%.(%d+)")

	local _major = tonumber(_major) or 1;
	local _minor = tonumber(_minor) or 1;

	_isForeverEngine = ( _major == 1 and _minor == 60);

	local parent = {
		addonName = _addonName,
		addonShortName = _addonShortName,
		addonPrefix = _addonPrefix,
		addonVersion = _addonVersion,
		addonAuthor = self.API.GetAddOnMetadata(_addonName, "Author") or "",
		addonExpansionLevel = _major,	-- Beware: Forever is 1 here!
		clientVersionMajor = _major,
		clientVersionMinor = _minor,
		clientVersionBuild = _build,
		ForeverEngine = _isForeverEngine,

		localPlayerName = self:GetFullName("player"),
		localPlayerNameNoSpaces = self:StripRealmSpaces(self:GetFullName("player")),
		localPlayerClass = self:GetUnitClass("player"),
		localPlayerFaction = self.API.UnitFactionGroup("player");
		localPlayerRealm = self:GetPlayerRealm("player"),
		localPlayerGUID = self.API.UnitGUID("player"),

		chatColorNormal = DIGAM_COLOR_BEGIN .. (addonSettings["NORMALCHATCOLOR"] or DIGAM_DEFAULT_ColorNormal),
		chatColorHot = DIGAM_COLOR_BEGIN..(addonSettings["HOTCHATCOLOR"] or DIGAM_DEFAULT_ColorHot),
		chatChannels = { },

		isDebugBuild = DIGAM_IsDebugBuild,
		buildVersion = DIGAM_BuildVersion,
	};
	
	setmetatable(parent, self);
	self.__index = self;

	parent:Initialize();

	return parent;
end;

--[[
Initialize the addon framework.
--]]
function DigamAddonLib:Initialize()
	self:Echo(string.format("Version %s by %s", self.addonVersion or "nil", self.addonAuthor or "nil"));
	if self.isDebugBuild then
		self:Echo(string.format("Using DigamAddonLib build %s.", self.buildVersion));
	end;

	self.API.RegisterAddonMessagePrefix(self.addonPrefix);
end;


--
--	ECHO Functions
--

--[[
Print a text in local using the addon's colours
Input: text to display
--]]
function DigamAddonLib:Echo(message)
	if message then
		message = string.format("%s-[%s%s%s]- %s%s", 
			self.chatColorNormal, 
			self.chatColorHot, 
			self.addonShortName, 
			self.chatColorNormal, 
			message, 
			DIGAM_CHAT_END
		);
		DEFAULT_CHAT_FRAME:AddMessage(message);
	end
end;

--	deprecated in 10.100, use Echo(message) instead.
function DigamAddonLib:echo(message)
	if message then
		message = string.format("%s-[%s%s%s]- %s%s", 
			self.chatColorNormal, 
			self.chatColorHot, 
			self.addonShortName, 
			self.chatColorNormal, 
			message, 
			DIGAM_CHAT_END
		);
		DEFAULT_CHAT_FRAME:AddMessage(message);
	end
end;

--[[
Check if the selected channel name is valid
--]]
function DigamAddonLib:ValidateChannel(channelName)
	local channel = self:GetChannelInfo(channelName);
	if channel then
		if self.API.IsInRaid() then
			--	Raid accepts everything, we even let people post in Party.
			if not self.API.UnitIsGroupAssistant("player") then
				if bit.band(channel["mask"], DIGAM_CHANNEL_RAIDWARNING["mask"]) > 0 then
					channel = DIGAM_CHANNEL_RAID;
				end;
			end;

		elseif self.API.GetNumGroupMembers() > 0 then
			--	Party: /r and /rw is forced into /p
			if bit.band(channel["mask"], 0x0003) > 0 then
				channel = DIGAM_CHANNEL_PARTY;
			end;

		else
			--	Solo: /r, /rw and /p is forced into local.
			if bit.band(channel["mask"], 0x0007) > 0 then
				--	Solo mode: force local output
				channel = nil;
			end;
		end;
	end;

	if channel then 
		return channel["name"];
	end
	return nil;
end;

--	deprecated in 10.100, use ValidateChannel(channelName) instead.
function DigamAddonLib:validateChannel(channelName)
	local channel = self:GetChannelInfo(channelName);
	if channel then
		if self.API.IsInRaid() then
			--	Raid accepts everything, we even let people post in Party.
			if not self.API.UnitIsGroupAssistant("player") then
				if bit.band(channel["mask"], DIGAM_CHANNEL_RAIDWARNING["mask"]) > 0 then
					channel = DIGAM_CHANNEL_RAID;
				end;
			end;

		elseif self.API.GetNumGroupMembers() > 0 then
			--	Party: /r and /rw is forced into /p
			if bit.band(channel["mask"], 0x0003) > 0 then
				channel = DIGAM_CHANNEL_PARTY;
			end;

		else
			--	Solo: /r, /rw and /p is forced into local.
			if bit.band(channel["mask"], 0x0007) > 0 then
				--	Solo mode: force local output
				channel = nil;
			end;
		end;
	end;

	if channel then 
		return channel["name"];
	end
	return nil;
end;

--[[
Echo in raid chat (if in raid), party chat (if im party) or local if solo.
]]
function DigamAddonLib:PartyEcho(message)
	if Thaliz.API.IsInRaid() then
		Thaliz.API.SendChatMessage(message, RAID_CHANNEL)
	elseif Thaliz.lib:IsInParty() then
		Thaliz.API.SendChatMessage(message, PARTY_CHANNEL)
	else
		self:Echo(message)
	end
end

--	deprecated in 10.100, stop using local chats, it wont work anymore! Consider PartyEcho(message) instead.
function DigamAddonLib:channelEcho(channelName, message)
	local channel = self:GetChannelInfo(channelName);
	if message and channel then
		if bit.band(channel["mask"], 0x07) > 0 then
			--	r, rw, p:
			self.API.SendChatMessage(message, channel["channel"]);
		else
			--	Custom channel, like a Healer channel etc:
			self.API.SendChatMessage(message, "CHANNEL", nil, tonumber(channel["channel"]));
		end;
	end;
end;

--[[
See if the current channel is available and return the channel properties
--]]
function DigamAddonLib:GetChannelInfo(channelName)
	for key, channel in next, self.chatChannels do
		if channel["name"] == channelName then
			return channel;
		end;
	end;
	return nil;
end;

--	deprecated since 10.100, use GetChannelInfo(channelName) instead
function DigamAddonLib:getChannelInfo(channelName)
	for key, channel in next, self.chatChannels do
		if channel["name"] == channelName then
			return channel;
		end;
	end;
	return nil;
end;

--[[
Send a whisper to another player.
--]]
function DigamAddonLib:SendWhisper(receiver, message)
	if receiver == self.localPlayerName then
		self:Echo(message);
	else
		self.API.SendChatMessage(message, WHISPER_CHANNEL, nil, receiver);
	end
end

--	deprecated since 10.100, use SendWhisper(receiver, message) instead
function DigamAddonLib:sendWhisper(receiver, message)
	if receiver == self.localPlayerName then
		self:echo(message);
	else
		self.API.SendChatMessage(message, WHISPER_CHANNEL, nil, receiver);
	end
end

--[[
Debug function to print an array
--]]
function DigamAddonLib:PrintAll(object, name, level)
	if not name then name = ""; end;
	if not level then level = 0; end;

	local indent = "";
	for n= 1, level, 1 do
		indent = indent .."  ";
	end;

	if type(object) == "string" then
		print(string.format("%s%s => %s", indent, name, object));
	elseif type(object) == "number" then
		print(string.format("%s%s => %s", indent, name, object));
	elseif type(object) == "boolean" then
		if object then
			print(string.format("%s%s => %s", indent, name, "true"));
		else
			print(string.format("%s%s => %s", indent, name, "false"));
		end;
	elseif type(object) == "function" then
		print(string.format("%s%s => %s", indent, name, "FUNCTION"));
	elseif type(object) == "nil" then
		print(string.format("%s%s => %s", indent, name, "NIL"));
	elseif type(object) == "table" then
		print(string.format("%s%s => {", indent, name));

		for key, value in next, object do
			self:PrintAll(value, key, level + 1);
		end;

		print(string.format("%s}", indent));
	end;
end;

StaticPopupDialogs["DIGAM_DIALOG_ERROR"] = {
	text = "%s",
	button1 = "OK",
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["DIGAM_DIALOG_CONFIRMATION"] = {
	text = "%s",
	button1 = "OK",
	button2 = "Cancel",
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(self, data, data2) DigamAddonLib.ShowConfirmation_Ok(); end,
	OnCancel = function(self, data, data2) DigamAddonLib.ShowConfirmation_Cancel(); end,
}

--[[
Convert the version number to an integer (if possible).
Returns 0 if not possible (like Alpha and Beta versions)
--]]
function DigamAddonLib:CalculateVersion(versionString)
	if not versionString then
		versionString = self.addonVersion;
	end;
	
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
	end
	
	return version;
end

--	Deprecated since 10.100, use CalculateVersion(versionString) instead
function DigamAddonLib:calculateVersion(versionString)
	if not versionString then
		versionString = self.addonVersion;
	end;
	
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
	end
	
	return version;
end


--
--	UI helpers
--	Note: 10.100 these changed to begin with upper case.
--
function DigamAddonLib:ShowError(errorMessage)
	StaticPopup_Show("DIGAM_DIALOG_ERROR", errorMessage);
end;

DigamAddonLib.FunctionOk = nil;
DigamAddonLib.FunctionCancel = nil;
function DigamAddonLib:ShowConfirmation(confirmationMessage, functionOk, functionCancel)
	DigamAddonLib.FunctionOk = functionOk;
	DigamAddonLib.FunctionCancel = functionCancel;
	StaticPopup_Show("DIGAM_DIALOG_CONFIRMATION", confirmationMessage);
end;

function DigamAddonLib.ShowConfirmation_Ok()
	if DigamAddonLib.FunctionOk then 
		DigamAddonLib.FunctionOk(); 
	end;
end;

function DigamAddonLib.ShowConfirmation_Cancel()
	if DigamAddonLib.FunctionCancel then 
		DigamAddonLib.FunctionCancel(); 
	end;
end;



--
--	WoW helpers
--

--[[
Return the UnitName in short form.
Examples:
Era: Mimma
Forever: Mimma
--]]
function DigamAddonLib:GetShortName(unitId)
	if not unitId then
		unitId = "player";
	end;

	local firstName, lastName = self.API.UnitName(unitId);

	return firstName;
end;

--[[
Return the UnitName in normal form.
Examples:
Era: Mimma Forever
Forever: Mimma
--]]
function DigamAddonLib:GetNormalName(unitId)
	--	The Forever engine have Firstname + Lastname: we only return Firstname:
	if not unitId then
		unitId = "player";
	end;

	local firstName, lastName = self.API.UnitName(unitId);

	if _isForeverEngine then
		if lastName and lastName ~= "" then
			firstName = firstName .." ".. lastName;
		end;
	end;

	return firstName;
end;

--[[
Return the UnitName in full form.
Examples:
Era: Mimma Forever
Forever: Mimma-Pyrewood Village
--]]
function DigamAddonLib:GetFullName(unitId)
	if not unitId then
		unitId = "player";
	end;
	local firstName, lastName = self.API.UnitName(unitId);
	if firstName then
		--	The Forever engine have Firstname + Lastname: we only return Firstname:
		if _isForeverEngine then
			if lastName and lastName ~= "" then
				firstName = firstName .." ".. lastName;
			end;
		else
			--	Era: LastName is the RealmName
			if not lastName or lastName == "" then
				lastName = self.API.GetRealmName();
			end;
			firstName = firstName .."-".. lastName;
		end;
	end;

	return firstName;
end;

--[[
Return UnitID from the playerName (preferable a full name).
Returns nil if not found.
--]]
function DigamAddonLib:GetUnitIdFromName(playerName)
	if playerName == self.localPlayerName then
		return "player";
	end

	if self.API.IsInRaid() then
		for n = 1, 40 do
			local unitId = "raid"..n;
			local unitname = self:GetFullName(unitId);
			
			if unitname and playerName == unitname then
				return unitId;
			end
		end
		
	elseif self.API.GetNumGroupMembers() > 0 then
		for n = 1, 4 do
			local unitId = "party"..n;
			local unitname = self:GetFullName(unitId);
			
			if unitname and playerName == unitname then
				return unitId;
			end
		end
	end

	return nil
end

--[[
Remove RealmName from the playerName.
This does nothing in Forever.
return name of player.
--]]
function DigamAddonLib:StripRealmName(playerName)
	if _isForeverEngine then
		return playerName;
	end

	local _, _, name = string.find(playerName, "([^-]*)-%s*");
	return name or playerName;
end;

--[[
Strip spaces in eventual realm name:
--]]
function DigamAddonLib:StripRealmSpaces(playername)
    local name, realm = string.match(playername, "([^-]+)%-(.*)")   
    if name and realm then
        return name .. "-" .. string.gsub(realm, " ", "")
    end
    return playername
end

--[[
ApplyRealmName to current name. Usefull on Era only.
--]]
function DigamAddonLib:ApplyRealmName(playerName)
	--	Forever: pass through; we cannot add last name!!
	if _isForeverEngine then
		return playerName;
	end;

	local _, _, name, realm = string.find(playerName, "([^-]*)-([%S ]*)");
	name = name or playerName;
	if name then
		if not realm then
			realm = self.localPlayerRealm;
		end;
		name = name ..'-'.. realm;
	end;

	return name;
end;

--	deprecated since 10.100. ApplyRealmName(playerName) works for Era.
function DigamAddonLib:getFullPlayerName(playerName)
	--	Forever: pass through; we cannot add last name!!
	if _isForeverEngine then
		return playerName;
	end;

	local _, _, name, realm = string.find(playerName, "([^-]*)-([%S ]*)");
	
	if realm then
		if string.find(realm, " ") then
			local _, _, name1, name2 = string.find(realm, "([a-zA-Z]*) ([a-zA-Z]*)");
			realm = name1 .. name2; 
		end;
	else
		name = playerName;
		realm = self.localPlayerRealm;
	end;

	return name .."-".. realm;
end;

--	deprecated since 10.100, use GetFullName(unitId)
function DigamAddonLib:getPlayerAndRealm(unitid, keepRealmnameSpaces)
	local playername, realmname = UnitName(unitid);

	if not playername then return nil; end;

	if _isForeverEngine then
		if realmname then
			playername = playername ..' '.. realmname;
		end;
		return playername;
	end;

	if not realmname or realmname == "" then
		realmname = self.API.GetRealmName();
	end;

	if not keepRealmnameSpaces and string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return playername.."-".. realmname;
end;

--[[
Return the english name of the UnitClas
return name of class in Upper case
--]]
function DigamAddonLib:GetUnitClass(unitId)
	local _, classname = self.API.UnitClass(unitId);
	return classname;
end;

--	deprecated since 10.100, use GetUnitClass(unitId)
--	Return the (english) name of the unit's class
function DigamAddonLib:unitClass(unitid)
	local _, classname = self.API.UnitClass(unitid);
	return classname;
end;

--[[
Return the Realm name.
return name of realm
--]]
function DigamAddonLib:GetPlayerRealm(unitId)
	local _, realmname = UnitName(unitId);
	if _isForeverEngine or not realmname or realmname == "" then
		realmname = self.API.GetRealmName();
	end;
	return realmname;
end;

--	deprecated since 10.100, use GetPlayerRealm(unitId) instead
function DigamAddonLib:getPlayerRealm(unitid)
	local playername, realmname = UnitName(unitid);
	if not realmname or realmname == "" then
		realmname = self.API.GetRealmName();
	end;
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;
	return realmname;
end;

--	Deprecated, use self.localPlayerRealm
function DigamAddonLib:getMyRealm()
	local realmname = self.API.GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

--[[
Check if you are in a party (group).
Returns true if in a party, false if not- Also false if you are in a raid.
--]]
function DigamAddonLib:IsInParty()
	return self.API.IsInGroup() and not self.API.IsInRaid()
end;

--	Deprecated since 10.100, use IsInParty()
function DigamAddonLib:isInParty()
	if not self.API.IsInRaid() then
		return ( self.API.GetNumGroupMembers() > 0 );
	end
	return false
end






--
--	Table functions
--
function DigamAddonLib:renumberTable(table)
	local newTable = { };

	for _, value in pairs(table) do
		tinsert(newTable, value);
	end;
	
	return newTable;
end;

function DigamAddonLib:cloneTable(sourceTable)
	if type(sourceTable) ~= "table" then return sourceTable; end;

	local t = { };
	for k, v in pairs(sourceTable) do
		t[k] = self:cloneTable(v);
	end;

	return setmetatable(t, self:cloneTable(getmetatable(sourceTable)));
end;



--
--	Channels
--

--	Updates the channel list (excuding General, Trade, Defense, LFG etc)
--	TRUE if group type check should be ignored; i.e. allow /rw in party
function DigamAddonLib:refreshChannelList(skipGroupTypeCheck)
	local channels = { };

	if skipGroupTypeCheck or self.API.IsInRaid() then
		tinsert(channels, DIGAM_CHANNEL_RAID);
		tinsert(channels, DIGAM_CHANNEL_RAIDWARNING); 
	end;
	
	if skipGroupTypeCheck or (not self.API.IsInRaid() and self.API.GetNumGroupMembers() > 0) then
		tinsert(channels, DIGAM_CHANNEL_PARTY);
	end;

	local publicChannels = { GetChatWindowChannels(DEFAULT_CHAT_FRAME:GetID()) };
	for n = 1, #publicChannels, 2 do
		--	0: Everywhere
		--	1: Current zone
		--	2: Major cities
		--	22: LocalDefence (!)

		--	So we want all zone 0 groups except LookingForGroup (translated)
		if publicChannels[n+1] == 0 and publicChannels[n] ~= self:XL("LookingForGroup") then
			local channelID, channelName = GetChannelName(publicChannels[n]);
			if channelID then
				tinsert(channels, {
					["id"] = tostring(channelID),
					["mask"] = DIGAM_CHANNEL_CUSTOM["mask"],
					["name"] = channelName,
					["channel"] = tostring(channelID),
				});
			end;
		end;
	end;

	self.chatChannels = channels;
end;



--
--	Addon communication
--

--[[
Send a message using the Addon channel.
--]]
function DigamAddonLib:SendAddonMessage(message)
	if self.API.IsInRaid() then
		self.API.SendAddonMessage(self.addonPrefix, message, "RAID");
	elseif self:IsInParty() then
		self.API.SendAddonMessage(self.addonPrefix, message, "PARTY");
	end;
end

--	Send a message using the Addon channel.
--	Deprecated sin ce 10.100, use SendAddonMessage(message) instead.
function DigamAddonLib:sendAddonMessage(message)
	local memberCount = self.API.GetNumGroupMembers();
	if memberCount > 0 then
		local channel;
		if self.API.IsInRaid() then
			channel = "RAID";
		elseif self:IsInParty() then
			channel = "PARTY";
		else 
			return;
		end;

		self.API.SendAddonMessage(self.addonPrefix, message, channel);
	end;
end
