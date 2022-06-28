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
local DIGAM_BuildVersion					= 6;

local DIGAM_COLOR_BEGIN						= "|c80";
local DIGAM_CHAT_END						= "|r";
local DIGAM_DEFAULT_ColorNormal				= "40A0F8"
local DIGAM_DEFAULT_ColorHot				= "B0F0F0"

local RAID_CHANNEL							= "RAID"
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

function DigamAddonLib:createLocale(languageCode)
	DigamAddonLib.Locales[languageCode] = { };
	return DigamAddonLib.Locales[languageCode];
end;

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

function DigamAddonLib:new(addonSettings)
	local _addonName = addonSettings["ADDONNAME"] or "Unnamed";
	local _addonShortName = addonSettings["SHORTNAME"] or _addonName;
	local _addonPrefix = addonSettings["PREFIX"] or _addonShortName;
	local _addonVersion = GetAddOnMetadata(_addonName, "Version") or 0;

	local parent = {
		addonName = _addonName,
		addonShortName = _addonShortName,
		addonPrefix = _addonPrefix,
		addonVersion = _addonVersion,
		addonAuthor = GetAddOnMetadata(_addonName, "Author") or "",
		addonExpansionLevel = tonumber(GetAddOnMetadata(_addonName, "X-Expansion-Level")),

		localPlayerName = self:getPlayerAndRealm("player"),
		localPlayerClass = self:getUnitClass("player"),
		localPlayerRealm = self:getPlayerRealm("player"),
		localPlayerGUID = UnitGUID("player"),

		chatColorNormal = DIGAM_COLOR_BEGIN .. (addonSettings["NORMALCHATCOLOR"] or DIGAM_DEFAULT_ColorNormal),
		chatColorHot = DIGAM_COLOR_BEGIN..(addonSettings["HOTCHATCOLOR"] or DIGAM_DEFAULT_ColorHot),
		chatChannels = { },

		isDebugBuild = DIGAM_IsDebugBuild,
		buildVersion = DIGAM_BuildVersion,
	};

	setmetatable(parent, self);
	self.__index = self;

	parent:initialize();

	return parent;
end;

function DigamAddonLib:initialize()
	self:echo(string.format("Version %s by %s", self.addonVersion or "nil", self.addonAuthor or "nil"));
	if self.isDebugBuild then
		self:echo(string.format("Using DigamAddonLib build %s.", self.buildVersion));
	end;

	C_ChatInfo.RegisterAddonMessagePrefix(self.addonPrefix);
end;



--
--	ECHO Functions
--
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

function DigamAddonLib:validateChannel(channelName)
	local channel = self:getChannelInfo(channelName);
	if channel then
		if IsInRaid() then
			--	Raid accepts everything, we even let people post in Party.
			if not UnitIsGroupAssistant("player") then
				if bit.band(channel["mask"], DIGAM_CHANNEL_RAIDWARNING["mask"]) > 0 then
					channel = DIGAM_CHANNEL_RAID;
				end;
			end;

		elseif GetNumGroupMembers() > 0 then
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

function DigamAddonLib:channelEcho(channelName, message)
	local channel = self:getChannelInfo(channelName);
	if message and channel then
		if bit.band(channel["mask"], 0x07) > 0 then
			--	r, rw, p:
			SendChatMessage(message, channel["channel"]);
		else
			--	Custom channel, like a Healer channel etc:
			SendChatMessage(message, "CHANNEL", nil, tonumber(channel["channel"]));
		end;
	end;
end;

function DigamAddonLib:printAll(object, name, level)
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
			self:printAll(value, key, level + 1);
		end;

		print(string.format("%s}", indent));
	end;
end;

function DigamAddonLib:getChannelInfo(channelName)
	for key, channel in next, self.chatChannels do
		if channel["name"] == channelName then
			return channel;
		end;
	end;
	return nil;
end;

function DigamAddonLib:sendWhisper(receiver, message)
	if receiver == self.localPlayerName then
		self:echo(message);
	else
		SendChatMessage(message, WHISPER_CHANNEL, nil, receiver);
	end
end


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

--	Convert the version number to an integer (if possible).
--	Returns 0 if not possible (like Alpha and Beta versions)
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
--
function DigamAddonLib:showError(errorMessage)
	StaticPopup_Show("DIGAM_DIALOG_ERROR", errorMessage);
end;

DigamAddonLib.FunctionOk = nil;
DigamAddonLib.FunctionCancel = nil;
function DigamAddonLib:showConfirmation(confirmationMessage, functionOk, functionCancel)
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
function DigamAddonLib:stripRealmName(nameAndRealm)
	local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*");
	return name or nameAndRealm;
end;

function DigamAddonLib:getFullPlayerName(playerName)
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

function DigamAddonLib:getPlayerAndRealm(unitid, keepRealmnameSpaces)
	local playername, realmname = UnitName(unitid);
	if not playername then return nil; end;

	if not realmname or realmname == "" then
		realmname = GetRealmName();
	end;

	if not keepRealmnameSpaces and string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return playername.."-".. realmname;
end;

function DigamAddonLib:getUnitClass(unitid)
	local _, classname = UnitClass(unitid);
	return classname;
end;

function DigamAddonLib:getPlayerRealm(unitid)
	local playername, realmname = UnitName(unitid);
	if not realmname or realmname == "" then
		realmname = GetRealmName();
	end;
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;
	return realmname;
end;

--	Deprecated, use self.localPlayerRealm
function DigamAddonLib:getMyRealm()
	local realmname = GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

function DigamAddonLib:isInParty()
	if not IsInRaid() then
		return ( GetNumGroupMembers() > 0 );
	end
	return false
end

--	Return the (english) name of the unit's class
function DigamAddonLib:unitClass(unitid)
	local _, classname = UnitClass(unitid);
	return classname;
end;

function DigamAddonLib:getUnitidFromName(playerName, keepRealmnameSpaces)
	local unitid, unitname;
	if IsInRaid() then
		for n = 1, 40, 1 do
			unitid = "raid"..n;
			unitname = UnitName(unitid);
			if not unitname then return nil; end;

			unitname = self:getPlayerAndRealm(unitid, keepRealmnameSpaces);
			if playerName == unitname then
				return unitid;
			end;
		end;
	elseif GetNumGroupMembers() > 0 then
		for n = 1, GetNumGroupMembers(), 1 do
			unitid = "party"..n;
			unitname = UnitName(unitid);
			if not unitname then 
				unitid = "player"; 
			end;
		
			unitname = self:getPlayerAndRealm(unitid, keepRealmnameSpaces);
			if playerName == unitname then
				return unitid;
			end;
		end;
	else
		--	Solo:
		if playerName == self.localPlayerName then
			return "player";
		end;
	end;

	return nil;
end;



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

	if skipGroupTypeCheck or IsInRaid() then
		tinsert(channels, DIGAM_CHANNEL_RAID);
		tinsert(channels, DIGAM_CHANNEL_RAIDWARNING); 
	end;
	
	if skipGroupTypeCheck or (not IsInRaid() and GetNumGroupMembers() > 0) then
		tinsert(channels, DIGAM_CHANNEL_PARTY);
	end;

	local publicChannels = { GetChatWindowChannels(DEFAULT_CHAT_FRAME:GetID()) };
	for n = 1, table.getn(publicChannels), 2 do
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

--	Send a message using the Addon channel.
function DigamAddonLib:sendAddonMessage(message)
	local memberCount = GetNumGroupMembers();
	if memberCount > 0 then
		local channel;
		if IsInRaid() then
			channel = "RAID";
		elseif self:isInParty() then
			channel = "PARTY";
		else 
			return;
		end;

		C_ChatInfo.SendAddonMessage(self.addonPrefix, message, channel);
	end;
end
